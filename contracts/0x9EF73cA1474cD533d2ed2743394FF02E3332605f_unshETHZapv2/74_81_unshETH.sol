// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC20PermitPermissionedMint } from "local/ERC20/ERC20PermitPermissionedMint.sol";

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