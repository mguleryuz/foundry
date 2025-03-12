// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {ERC20Issuance_v1} from "@/ERC20Issuance_v1.sol";

contract ERC20Issuance_v1Test is Test {
    // CONSTANTS
    uint constant MAX_SUPPLY = type(uint256).max - 1;
    string constant NAME = "MyToken";
    string constant SYMBOL = "MTK";
    uint8 constant DECIMALS = 18;

    // VARIABLES
    ERC20Issuance_v1 public token;
    address public deployer = address(this); // The test contract will act as the deployer

    function setUp() public {
        // Deploy the MyToken contract
        token = new ERC20Issuance_v1(
            NAME,
            SYMBOL,
            DECIMALS,
            MAX_SUPPLY,
            deployer
        );
    }

    function testMint() public {
        // Set the mint amount
        uint mintAmount = 1000;

        // Mint the tokens to the deployer's address
        token.mint(deployer, mintAmount);

        // Check that the initial supply was allocated to the deployer's address
        uint deployerBalance = token.balanceOf(deployer);

        assertEq(
            deployerBalance,
            mintAmount,
            "Deployer should have the minted amount"
        );
    }

    function testTokenDetails() public view {
        assertEq(token.name(), NAME, "Token name should be MyToken");
        assertEq(token.symbol(), SYMBOL, "Token symbol should be MTK");
        assertEq(token.decimals(), DECIMALS, "Token decimals should be 18");
    }
}
