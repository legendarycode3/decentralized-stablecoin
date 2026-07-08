// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC20Burnable, ERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";



/**
 * @title MockFailedMintDSC
 * @author LegendaryCode
 * @notice A mock DecentralizedStableCoin (DSC) used for testing edge cases.
 * @dev Inherits from ERC20Burnable and Ownable. This mock intentionally returns `false` 
 *      on minting attempts to simulate a failed mint scenario in test environments.
*/
contract MockFailedMintDSC is ERC20Burnable, Ownable {
    /// @notice Custom Errors for gas efficiency and clearer debugging
    error DecentralizedStableCoin__AmountMustBeMoreThanZero();
    error DecentralizedStableCoin__BurnAmountExceedsBalance();
    error DecentralizedStableCoin__NotZeroAddress();

   
    /**
     * @notice Initializes the token with a name, symbol, and initial owner.
     * @param initialOwner The address of the contract owner.
    */
    constructor(address initialOwner) ERC20("DecentralizedStableCoin", "DSC") Ownable(initialOwner) { }
    

    /**
     * @notice Burns a specific amount of tokens from the owner's account.
     * @dev Overrides ERC20Burnable to add ownership and zero-amount checks.
     * @param _amount The amount of tokens to be burned.
    */
    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);

        // Revert if the burn amount is zero or negative
        if (_amount <= 0) {
            revert DecentralizedStableCoin__AmountMustBeMoreThanZero();
        }

        // Revert if the user does not have enough tokens to burn
        if (balance < _amount) {
            revert DecentralizedStableCoin__BurnAmountExceedsBalance();
        }

        // Execute the burning logic from parent contract
        super.burn(_amount);
    }


    /**
     * @notice Mints new tokens to a specified address.
     * @dev Restricted to the owner. Intentionally returns `false` to mock a failed minting 
     *      transaction.
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return bool Returns false unconditionally to simulate failure.
    */
    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        // Revert if minting to the zero address
        if (_to == address(0)) {
            revert DecentralizedStableCoin__NotZeroAddress();
        }

        // Revert if the mint amount is zero or negative
        if (_amount <= 0) {
            revert DecentralizedStableCoin__AmountMustBeMoreThanZero();
        }

        // Mint the tokens to the recipient
        _mint(_to, _amount);

        // Intentionally return false for testing purposes (even though _mint succeeded)
        return false;
    }
}