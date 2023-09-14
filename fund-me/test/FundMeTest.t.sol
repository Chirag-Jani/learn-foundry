// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// to import test functionality
import {Test, console} from "forge-std/Test.sol";

// importing contract
import {FundMe} from "../src/FundMe.sol";

contract FundMeTest is Test {
    FundMe public fundMe;

    function setUp() public {
        // vm.prank(
        //     vm.addr(
        //         0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        //     )
        // );
        fundMe = (new FundMe());
    }

    function testMinUsdAmount() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerAddress() public {
        // assertEq(
        //     fundMe.i_owner(),
        //     vm.addr(
        //         0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        //     )
        // );
        // console.log("Owner ------------", fundMe.i_owner());
        // console.log(
        //     "msg.sender ------------",
        //     vm.addr(
        //         0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        //     )
        // );
        assertEq(fundMe.i_owner(), address(this));
    }

    // forge test -vvvv mt testPriceFeedVersion --fork-url <sepolia_rpc_url_from_alchemy>
    // function testPriceFeedVersion() public {
    //     assertEq(fundMe.getVersion(), 4);
    // }
}