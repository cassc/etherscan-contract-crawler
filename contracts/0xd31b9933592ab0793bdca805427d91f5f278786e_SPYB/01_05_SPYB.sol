// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spy Balloon Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    ISPY    //
//            //
//            //
////////////////


contract SPYB is ERC1155Creator {
    constructor() ERC1155Creator("Spy Balloon Editions", "SPYB") {}
}