// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NOIR CHRONICLES
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    NOIR    //
//            //
//            //
////////////////


contract NOIR is ERC721Creator {
    constructor() ERC721Creator("NOIR CHRONICLES", "NOIR") {}
}