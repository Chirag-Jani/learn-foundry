// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title DSCEngine
 * @author Chirag Jani
 * @notice This is the main contract that is going to control the DecentralizedStableCoin contract. It handles all the logic
 * for minting and redeeming DSC, as well as depositing and withdrawing collateral.
 * @notice This contract is based on the MakerDAO DSS system
 * @notice Our DSC system should always be Overcollateralized. At no point in time, should the value of all collateral <= the $ backed value of all the DSC
 *
 * This is similar to DAI if DAI had no governance, no fees, and was backed by only wETH and wBTC.
 *
 * This system is designed to be as minimal as possible and have the tokens maitain a 1 token == $1 peg at all times.
 * This is a StableCoin with the below properties:
 *  - Exogenously Collateralized (as Doller is used for Pegging / Anchoring)
 *  - Dollar Pegged
 *  - Algorithmically Stable
 *
 * @custom:about-collateral A user Must have minimum 150% of the total holding (of Stablecoin) in the system. i.e if a user hold $100 worth of DSC, he should have mimimum $150 worth of wETH/wBTC as collateral
 */

contract DSCEngine is ReentrancyGuard {
    error DSCEngine_AmountZeroError();
    error DSCEngine_TokenNotAllowed();
    error DSCEngine_TokenAddressAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine_TransferFailed();
    error DSCEngine_BreaksHealthFactor(uint256 healthFactor);

    uint256 private constant _ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant _PRECISION = 1e18;
    uint256 private constant _LIQUIDATION_THRESHOLD = 50;
    uint256 private constant _LIQUIDATION_PRECISION = 100;
    uint256 private constant _MIN_HEALTH_FACTOR = 1;

    mapping(address token => address priceFeed) private _tokenToPriceFeed; // used as s_priceFeeds in PC video
    mapping(address user => mapping(address token => uint256 amount)) private _userCollateralDeposited;
    mapping(address user => uint256 amount) private _amountDSCMintedByUser;
    address[] private _collateralTokens;

    DecentralizedStableCoin private immutable _dscAddress;

    event CollateralDeposited(
        address indexed sender, address indexed collateralTokenAddress, uint256 indexed collateralAmount
    );

    modifier moreThanZero(uint256 _amount) {
        if (_amount <= 0) {
            revert DSCEngine_AmountZeroError();
        }
        _;
    }

    modifier isTokenAllowed(address tokenAddress) {
        if (_tokenToPriceFeed[tokenAddress] == address(0)) {
            revert DSCEngine_TokenNotAllowed();
        }
        _;
    }

    /**
     * @param tokenAddresses addresses of the token
     * @param tokenPriceFeedAddresses addresses of the priceFeed of the token from the Chainlink
     * @param dscAddress address of our DecentralizedStableCoin contract as our engine will need to call several functions like "burn"
     */
    constructor(address[] memory tokenAddresses, address[] memory tokenPriceFeedAddresses, address dscAddress) {
        if (tokenAddresses.length != tokenPriceFeedAddresses.length) {
            revert DSCEngine_TokenAddressAndPriceFeedAddressesMustBeSameLength();
        }

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            _tokenToPriceFeed[tokenAddresses[i]] = tokenPriceFeedAddresses[i];
            _collateralTokens.push(tokenAddresses[i]);
        }

        _dscAddress = DecentralizedStableCoin(dscAddress);
    }

    function depositeCollateralAndMintDSC() external {}

    /**
     * @notice uses CEI (Checks -> Effects -> Interactions)
     * @param collateralTokenAddress address of the token that user is going to put as collateral
     * @param collateralAmount amount of the token that user is going to put as collateral
     */
    function depositeCollateral(address collateralTokenAddress, uint256 collateralAmount)
        external
        isTokenAllowed(collateralTokenAddress)
        moreThanZero(collateralAmount)
        nonReentrant
    {
        _userCollateralDeposited[msg.sender][collateralTokenAddress] += collateralAmount;
        emit CollateralDeposited(msg.sender, collateralTokenAddress, collateralAmount);
        bool success = IERC20(collateralTokenAddress).transferFrom(msg.sender, address(this), collateralAmount);
        if (!success) {
            revert DSCEngine_TransferFailed();
        }
    }

    function redeemCollateralForDSC() external {}

    function redeemCollateral() external {}

    /**
     * @notice follows CEI
     * @param amountDSCToMint amount of DSC tokens to Mint
     * @notice user must have more collateral value than minimum threshold
     */
    function mintDSC(uint256 amountDSCToMint) external moreThanZero(amountDSCToMint) nonReentrant {
        _amountDSCMintedByUser[msg.sender] += amountDSCToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function burnDSC() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}

    /**
     *
     * @param user address of the user
     * @return totalDSCMinted total DSC token minted by the user
     * @return collateralValueInUsd total value of the deposited collateral by the user in USD (as our coin is USD pegged)
     */
    function _getAccountInfo(address user)
        private
        view
        returns (uint256 totalDSCMinted, uint256 collateralValueInUsd)
    {
        totalDSCMinted = _amountDSCMintedByUser[user];
        collateralValueInUsd = getCollateralValueInUsd(user);

        return (totalDSCMinted, collateralValueInUsd);
    }

    /**
     *
     * @param user address of the user whose health factor we are going to get
     * @return uint returns how close a user is to liquidation
     *              if a user goes below 1, they can get liquidated
     */
    function _healthFactor(address user) private view returns (uint256) {
        // we need total DSC minted
        // total VALUE of collateral (in USD)
        (uint256 totalDSCMinted, uint256 collateralValueInUsd) = _getAccountInfo(user);
        uint256 collateralThresholdAdjusted = (collateralValueInUsd * _LIQUIDATION_THRESHOLD) / _LIQUIDATION_PRECISION;

        return (collateralThresholdAdjusted * _PRECISION) / totalDSCMinted;
    }

    /**
     *
     * @param user address of the user whose health factor we want to check
     */
    function _revertIfHealthFactorIsBroken(address user) internal view {
        // check health factor (do they have enough collateral?)
        // revert if they don't
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < _MIN_HEALTH_FACTOR) {
            revert DSCEngine_BreaksHealthFactor(userHealthFactor);
        }
    }

    /**
     *
     * @param user address of the user
     * @return collateralValueInUsd value of the collateral in USD (as our coin is USD pegged)
     */
    function getCollateralValueInUsd(address user) public view returns (uint256 collateralValueInUsd) {
        for (uint256 i = 0; i < _collateralTokens.length; i++) {
            address tokenAddress = _collateralTokens[i];
            uint256 amount = _userCollateralDeposited[user][tokenAddress];
            collateralValueInUsd += getUsdValue(tokenAddress, amount);
        }
        return collateralValueInUsd;
    }

    function getUsdValue(address tokenAddress, uint256 tokenAmount) public view returns (uint256 tokenValueInUsd) {
        address tokenPriceFeedAddress = _tokenToPriceFeed[tokenAddress];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(tokenPriceFeedAddress);
        (, int256 price,,,) = priceFeed.latestRoundData();

        // if 1 ETH = $1,000
        // returned value from CL will be 1,000 * 1e8

        return ((uint256(price) * _ADDITIONAL_FEED_PRECISION) * tokenAmount) / _PRECISION;
    }
}
