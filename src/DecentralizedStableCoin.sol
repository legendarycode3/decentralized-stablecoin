// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol"; 
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @title  DecentralizedStableCoin
 * @author LegendaryCode
 * Collateral: Exogenous (ETH & BTC)
 * Minting: Algorithmic 
 * Relative Stability: Pegged to USD
 * 
 * This is the contract meant to be governed by DSCEngine. It is just the ERC20 implementation of our stablecoin. 
 */
contract DecentralizedStableCoin is ERC20Burnable, Ownable {

    /// @notice Custom errors for gas efficiency and clear debugging
    error DecentralizedStableCoin__MustBeMoreThanZero();
    error DecentralizedStableCoin__BurnAmountExceedsBalance();
    error DecentralizedStableCoin__NotZeroAddress();

        
    /**
    * @notice The constructor executes exactly once during contract deployment.
    * @dev Inherits from ERC20 and Ownable to set up the DecentralizedStableCoin.
    * @param initialOwner The address that will initially hold administrative rights   
    *        (ownership) over the smart contract.
    */
    constructor(address initialOwner) ERC20("DecentralizedStableCoin", "DSC") Ownable(initialOwner) {

    }

    
    /**
    * @notice Destroys a specific amount of tokens from the owner's account.
    * @dev Overrides the standard ERC20 burn function to add custom access control and 
    *       validation checks. Can only be called by the contract owner.
    * @param _amount The quantity of tokens to be destroyed.
    */
    function burn(uint256 _amount) public override onlyOwner {
        //  Fetch the current token balance of the caller (the contract owner).
        uint256 balance = balanceOf(msg.sender);

        // Validate that the burn amount is strictly greater than zero.
        if(_amount <= 0) {
            revert DecentralizedStableCoin__MustBeMoreThanZero();
        }
        
        // Validate that the owner actually has enough tokens to cover the burn amount. If the requested burn amount exceeds the available balance, the transaction reverts.
        if(balance < _amount) {
            revert DecentralizedStableCoin__BurnAmountExceedsBalance();
        }

        // Call the parent contract's burn function (e.g., OpenZeppelin's ERC20Burnable) (This reduces the total supply of the token and deducts the tokens from the owner's balance).
        super.burn(_amount);
    }


    /**
    * @notice Mints new tokens to a specified address. 
    * @dev This function can only be called by the contract owner. It includes input 
    *      validation to prevent minting to the zero address or minting zero tokens.
    * 
    * @param _to The address that will receive the newly minted tokens.
    * @param _amount The quantity of tokens to be minted.
    * @return success Returns `true` if the minting process completes successfully.
    */
    function mint(address _to, uint256 _amount) external onlyOwner returns(bool) {
        // This ensures tokens aren't accidentally locked forever in an inaccessible address.
        if(_to == address(0)) {
            revert DecentralizedStableCoin__NotZeroAddress();
        }

        // This enforces that only positive token values are created.
        if(_amount <= 0) 
            revert DecentralizedStableCoin__MustBeMoreThanZero();
        

        // Execute the internal minting logic
        _mint(_to, _amount);

        // Return true to explicitly confirm the successful execution of the function.
        return true;
    }
}
