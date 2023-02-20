// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DENKUR
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    DENK    //
//            //
//            //
////////////////


contract DENK is ERC721Creator {
    constructor() ERC721Creator("DENKUR", "DENK") {}
}