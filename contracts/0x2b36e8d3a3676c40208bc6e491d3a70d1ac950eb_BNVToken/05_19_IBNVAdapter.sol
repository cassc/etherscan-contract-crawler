// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @title BNV Adapter Interface 
/// @author Sensible Lab
/// @dev adapter for external contract integration
interface IBNVAdapter {

    // VIEW ONLY =======================================

    function hasPermission(address owner, address operator) external view returns (bool);

}