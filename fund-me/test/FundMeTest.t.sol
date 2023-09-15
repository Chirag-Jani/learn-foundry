// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// to import test functionality
import {Test, console} from "forge-std/Test.sol";

// importing contract
import {FundMe} from "../src/FundMe.sol";
import {FundMeDeploy} from "../script/FundMeDeploy.s.sol";

contract FundMeTest is Test {
    FundMe public fundMe;

    function setUp() public {
        // old way of deploying
        // fundMe = (new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306));

        // new way
        FundMeDeploy fundMeDeploy = new FundMeDeploy();
        fundMe = fundMeDeploy.run();
    }

    function testMinUsdAmount() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerAddress() public {
        assertEq(fundMe.i_owner(), msg.sender);
    }

    // forge test -vvvv mt testPriceFeedVersion --fork-url <sepolia_rpc_url_from_alchemy>
    function testPriceFeedVersion() public {
        assertEq(fundMe.getVersion(), 4);
    }
}
