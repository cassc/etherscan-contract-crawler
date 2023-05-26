// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC20PermitPermissionedMint } from "local/ERC20/ERC20PermitPermissionedMint.sol";

/*
* shETH Contract:
* This contract is already ERC-20 compliant, and handles the creation and management of shETH tokens.
*
* TODO:
* 1) Implement the unshETH-specific reward mechanism for users that lock their shETH tokens.
* 2) Implement a function to check the remaining lock time for user's shETH tokens.
* 3) Implement testing for the reward mechanism.
* 4) Perform a security audit for the contract.
*/
contract unshETH is ERC20PermitPermissionedMint {

    address public LSDRegistryAddress;
    /* ========== CONSTRUCTOR ========== */
    constructor(
      address _creator_address,
      address _timelock_address
    ) 
    ERC20PermitPermissionedMint(_creator_address, _timelock_address, "unshETH Ether", "unshETH") 
    {}
}