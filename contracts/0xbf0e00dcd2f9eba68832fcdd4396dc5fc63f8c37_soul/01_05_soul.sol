// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: soul
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    soul    //
//            //
//            //
////////////////


contract soul is ERC721Creator {
    constructor() ERC721Creator("soul", "soul") {}
}