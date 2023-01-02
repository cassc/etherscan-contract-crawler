// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 黄金郷
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    ŌGONKYŌ     //
//                //
//                //
////////////////////


contract OG is ERC721Creator {
    constructor() ERC721Creator(unicode"黄金郷", "OG") {}
}