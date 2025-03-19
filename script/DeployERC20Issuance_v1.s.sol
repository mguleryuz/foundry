// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {ERC20Issuance_v1} from "src/ERC20Issuance_v1.sol";

contract DeployERC20Issuance_v1 is Script {
    function run() public {
        // Retrieve the private key from the .env file
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // Define the token parameters
        string memory name = "JIM AIGent";
        string memory symbol = "JIM";
        uint256 maxSupply = type(uint256).max - 1;
        uint8 decimals = 18;
        address initialAdmin = vm.addr(privateKey);

        // Start broadcasting transactions
        vm.startBroadcast(privateKey);

        // Deploy the Token contract
        ERC20Issuance_v1 token = new ERC20Issuance_v1(name, symbol, decimals, maxSupply, initialAdmin);

        // Log the address of the deployed contract
        console.log("Deployed Token at address: ", address(token));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
