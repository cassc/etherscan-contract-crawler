// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: stories, imperfect
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    sToRiEs,ImPeRfEcT    //
//                         //
//                         //
/////////////////////////////


contract STORY is ERC721Creator {
    constructor() ERC721Creator("stories, imperfect", "STORY") {}
}