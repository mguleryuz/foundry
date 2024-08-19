// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {Token} from "../src/Token.sol";

contract DeployToken is Script {
    function run() public {
        // Retrieve the private key from the .env file
        string memory privateKey = vm.envString("PRIVATE_KEY");

        // Define the token parameters
        string memory name = "Verifier Token";
        string memory symbol = "VERIFY";
        uint256 initialSupply = 100;
        uint8 decimals = 18;

        // Convert the private key to an account
        vm.startBroadcast(privateKey);

        // Deploy the Token contract
        Token token = new Token(name, symbol, decimals, initialSupply);

        // Log the address of the deployed contract
        console.log("Deployed Token at address: ", address(token));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
