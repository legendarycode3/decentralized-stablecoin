// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { ERC20Mock } from "./ERC20Mock.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


/**
 *  @title MockFailedTransfer
 *  @notice A mock ERC20 token contract
 *  @dev Inherits from ERC20Mock. Overrides standard transfer behavior to return false 
 *       instead of true.
 */
contract MockFailedTransfer is ERC20Mock, Ownable {

    /**
     *  @notice Initializes the mock token with predefined values
     *  @param user The address to receive the initial token supply
     */
    constructor(address user) 
        ERC20Mock("FAIL", "FAIL", user, 100e18)
        Ownable(msg.sender)
    {}


    /**
     * @notice Intentionally fails and denies any `transferFrom` call
     * @dev Overrides the standard ERC20 `transferFrom` logic to strictly return `false`.
     * @return success Always returns false to simulate a failed transfer execution
     */
    function transferFrom(
        address,        // from
        address,        // to
        uint256         // amount
    ) public pure override returns (bool) {
         // Explicitly return false instead of executing the transfer
        return false;
    }
}