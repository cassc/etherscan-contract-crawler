// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 *  The `Role` is a contract extension for any base NFT contract. It lets you manage role of address
 */

 abstract contract Role {
   /// @dev Checks whether caller has admin role
    function verifyAdminRole() internal view virtual returns (bool); 

   /// @dev Checks whether caller has mint role
    function verifyMintRole() internal view virtual returns (bool); 
 }