// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/**
 * @title ERC20Mock
 * @author LegendaryCode
 * @notice A mock ERC20 contract exposing internal OpenZeppelin functions for testing 
 *         purposes.
 * @dev This contract should strictly be used in a local test environment. Never deploy to 
 *      mainnet.
 */
contract ERC20Mock is ERC20 {

    /**
     * @notice Initializes the mock token and mints an initial supply to a specified account.
     * @param name The human-readable name of the token.
     * @param symbol The ticker symbol of the token.
     * @param initialAccount The wallet address receiving the initial token supply.
     * @param initialBalance The amount of tokens to mint initially.
    */
    constructor(
        string memory name,
        string memory symbol,
        address initialAccount,
        uint256 initialBalance
    )
        payable
        ERC20(name, symbol)
    {
        // Mint the starting token supply to the designated test account
        _mint(initialAccount, initialBalance);
    }


    /**
     * @notice Mints new tokens to any address without restriction.
     * @dev Exposes the internal `_mint` function as public for test manipulation.
     * @param account The address that will receive the minted tokens.
     * @param amount The quantity of tokens to create.
    */
    function mint(address account, uint256 amount) public {
         // Call the internal OpenZeppelin mint logic
        _mint(account, amount);
    }


    /**
     * @notice Destroys a specified amount of tokens from an address.
     * @dev Exposes the internal `_burn` function as public for test manipulation.
     * @param account The address whose tokens will be destroyed.
     * @param amount The quantity of tokens to burn.
    */
    function burn(address account, uint256 amount) public {
         // Call the internal OpenZeppelin burn logic
        _burn(account, amount);
    }


    /**
     * @notice Forces a token transfer between two addresses without requiring approval.
     * @dev Exposes the internal `_transfer` function to bypass standard allowance checks 
     *      during testing.
     * @param from The address sending the tokens.
     * @param to The address receiving the tokens.
     * @param value The quantity of tokens being moved.
    */
    function transferInternal(address from, address to, uint256 value) public {
        // Bypass the allowance check and transfer tokens directly
        _transfer(from, to, value);
    }


    /**
     * @notice Forces an approval rule between an owner and a spender.
     * @dev Exposes the internal `_approve` function to set allowances directly during 
     *      testing.
     * @param owner The address granting the spending allowance.
     * @param spender The address authorized to spend the tokens.
     * @param value The allowance limit being set.
    */
    function approveInternal(address owner, address spender, uint256 value) public {
        // Set the allowance directly without triggering an external transaction from the owner
        _approve(owner, spender, value);
    }
}