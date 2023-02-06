// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: City-Checks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    OZR-CITY-Checks    //
//                       //
//                       //
///////////////////////////


contract OZRCTChecks is ERC1155Creator {
    constructor() ERC1155Creator("City-Checks", "OZRCTChecks") {}
}