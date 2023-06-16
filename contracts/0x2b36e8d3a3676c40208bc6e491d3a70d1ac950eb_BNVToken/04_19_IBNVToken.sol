// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @title BNV Token Interface 
/// @author Sensible Lab
interface IBNVToken {

    // VIEW ONLY =======================================

    function isWhiteList(address sender, address operator) external view returns (bool);

}