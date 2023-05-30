// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Yutori Travel Journal B
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    Japanese illustrator     //
//                             //
//                             //
/////////////////////////////////


contract YTJB is ERC721Creator {
    constructor() ERC721Creator("Yutori Travel Journal B", "YTJB") {}
}