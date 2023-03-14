// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SOLO Birthday
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    SOLO    //
//            //
//            //
////////////////


contract SL is ERC721Creator {
    constructor() ERC721Creator("SOLO Birthday", "SL") {}
}