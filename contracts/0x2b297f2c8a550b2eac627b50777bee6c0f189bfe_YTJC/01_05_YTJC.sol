// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Yutori Travel Journal C
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    Japanese illustrator     //
//                             //
//                             //
/////////////////////////////////


contract YTJC is ERC1155Creator {
    constructor() ERC1155Creator("Yutori Travel Journal C", "YTJC") {}
}