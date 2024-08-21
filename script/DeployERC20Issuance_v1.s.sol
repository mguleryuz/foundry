// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {ERC20Issuance_v1} from "../src/ERC20Issuance_v1.sol";

contract DeployERC20Issuance_v1 is Script {
    function run() public {
        // Retrieve the private key from the .env file
        uint256 privateKey = vm.envUint("TEST_PRIVATE_KEY");

        // Define the token parameters
        string memory name = "Verifier Token";
        string memory symbol = "VERIFY";
        uint256 maxSupply = 100;
        uint8 decimals = 18;
        address initialAdmin = address(this);

        // Start broadcasting transactions
        vm.startBroadcast(privateKey);

        // Deploy the Token contract
        ERC20Issuance_v1 token = new ERC20Issuance_v1(
            name,
            symbol,
            decimals,
            maxSupply,
            initialAdmin
        );

        // Log the address of the deployed contract
        console.log("Deployed Token at address: ", address(token));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
