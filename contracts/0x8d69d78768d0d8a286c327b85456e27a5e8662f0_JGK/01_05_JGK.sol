// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jagodka
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    NUUUDE ART     //
//                   //
//                   //
///////////////////////


contract JGK is ERC1155Creator {
    constructor() ERC1155Creator("Jagodka", "JGK") {}
}