// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TOUCH
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    touch by alister mori    //
//                             //
//                             //
/////////////////////////////////


contract touch is ERC721Creator {
    constructor() ERC721Creator("TOUCH", "touch") {}
}