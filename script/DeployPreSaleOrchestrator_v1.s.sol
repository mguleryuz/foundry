// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {PreSaleOrchestrator_v1} from "src/PreSaleOrchestrator_v1.sol";

contract DeployPreSaleOrchestrator_v1 is Script {
    function run() public {
        // Retrieve the private key from the .env file
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(privateKey);

        // Deploy the Token contract
        PreSaleOrchestrator_v1 preSaleOrchestrator = new PreSaleOrchestrator_v1();

        // Log the address of the deployed contract
        console.log("Deployed PreSaleOrchestrator at address: ", address(preSaleOrchestrator));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
