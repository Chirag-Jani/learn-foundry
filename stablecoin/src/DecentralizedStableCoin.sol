// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DecentralizedStableCoin
 * @author Chirag Jani
 * @notice None
 * Collateral : Exogenous (wETH & wBTC)
 * Minting : Algorithmic (Decentralized)
 * Relative Stability : Pegged to USD
 *
 * This contract is meant to be governed by DSCEngine.
 * This contract is just the ERC20 implementation of our StableCoin System
 */

contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    error DecentralizedStableCoin_MustBeMoreThanZero();
    error DecentralizedStableCoin_BurnAmountExceedsBalance();
    error DecentralizedStableCoin_AddressNotAllowed();

    constructor() ERC20("Jani's Decentralized StableCoin", "DSC") {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 bal = balanceOf(msg.sender);

        if (_amount <= 0) {
            revert DecentralizedStableCoin_MustBeMoreThanZero();
        }

        if (_amount > bal) {
            revert DecentralizedStableCoin_BurnAmountExceedsBalance();
        }

        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DecentralizedStableCoin_AddressNotAllowed();
        }

        if (_amount <= 0) {
            revert DecentralizedStableCoin_MustBeMoreThanZero();
        }

        _mint(_to, _amount);

        return true;
    }
}

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations (Using SafeMath for Uint)
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
