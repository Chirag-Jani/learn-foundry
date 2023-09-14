// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/FundMe.sol";

contract FundMeDeploy is Script {
    function run() external returns (FundMe) {
        vm.startBroadcast();
        FundMe fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306); // 0x694AA1769357215DE4FAC081bf1f309aDC325306 (sepolia address)
        vm.stopBroadcast();
        return fundMe;
    }
}
