// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockERC20
 * @notice A basic mock ERC20 token for testing
 * @dev Extends OpenZeppelin's ERC20 with minting capability
 */
contract MockERC20 is ERC20 {
    uint8 private _decimals;

    /**
     * @notice Constructor to create a new mock token
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param decimals_ The number of decimals for the token
     */
    constructor(string memory name, string memory symbol, uint8 decimals_) ERC20(name, symbol) {
        _decimals = decimals_;
    }

    /**
     * @notice Returns the number of decimals used for this token
     * @return The number of decimals
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Mints tokens to a specified address (for testing purposes)
     * @param to The address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    /**
     * @notice Burns tokens from the caller's address (for testing purposes)
     * @param amount The amount of tokens to burn
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
