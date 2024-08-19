// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import "../src/Token.sol";

contract TokenTest is Test {
    Token public token;
    address public deployer = address(this); // The test contract will act as the deployer

    function setUp() public {
        // Initial supply of 1 million tokens with 18 decimals
        uint256 initialSupply = 1000000 * 10 ** 18;

        // Deploy the MyToken contract
        token = new Token("MyToken", "MTK", 18, initialSupply);
    }

    function testInitialSupply() public view {
        // Check that the initial supply was allocated to the deployer's address
        uint256 deployerBalance = token.balanceOf(deployer);
        uint256 totalSupply = token.totalSupply();

        assertEq(
            deployerBalance,
            totalSupply,
            "Deployer should have the entire initial supply"
        );
    }

    function testTokenDetails() public view {
        // Verify that the token details are set correctly
        console.log("Token name: ", token.name());
        console.log("Token symbol: ", token.symbol());
        console.log("Token decimals: ", token.decimals());

        assertEq(token.name(), "MyToken", "Token name should be MyToken");
        assertEq(token.symbol(), "MTK", "Token symbol should be MTK");
        assertEq(token.decimals(), 18, "Token decimals should be 18");
    }
}
