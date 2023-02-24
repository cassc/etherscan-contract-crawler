// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: More Moments & More Memories
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Jord Explores    //
//                     //
//                     //
/////////////////////////


contract MMMM is ERC721Creator {
    constructor() ERC721Creator("More Moments & More Memories", "MMMM") {}
}