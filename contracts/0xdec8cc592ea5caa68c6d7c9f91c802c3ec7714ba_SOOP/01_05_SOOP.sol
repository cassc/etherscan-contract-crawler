// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Campbell's Soup Can (Tomato)
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    War.hole.    //
//                 //
//                 //
/////////////////////


contract SOOP is ERC1155Creator {
    constructor() ERC1155Creator("Campbell's Soup Can (Tomato)", "SOOP") {}
}