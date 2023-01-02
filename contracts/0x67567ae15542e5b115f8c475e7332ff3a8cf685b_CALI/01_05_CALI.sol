// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: California State of Mind
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    by _HIPSTER    //
//                   //
//                   //
///////////////////////


contract CALI is ERC721Creator {
    constructor() ERC721Creator("California State of Mind", "CALI") {}
}