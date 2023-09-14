// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";

contract DeploySimpleStorage is Script {
    // run function is executed when we deploy
    function run() external returns (SimpleStorage) {
        // starts the broadcast (sends everything on our RPC endpoint)
        vm.startBroadcast();

        // creating instance
        SimpleStorage simpleStorage = new SimpleStorage();

        // ends the broadcast
        vm.stopBroadcast();

        return simpleStorage;
    }
}
