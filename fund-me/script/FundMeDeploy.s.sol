// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract FundMeDeploy is Script {
    function run() external returns (FundMe) {
        HelperConfig hC = new HelperConfig();
        address ethUsdPriceFeed = hC.activeNetwork();
        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed); // 0x694AA1769357215DE4FAC081bf1f309aDC325306 (sepolia address)
        vm.stopBroadcast();
        return fundMe;
    }
}
