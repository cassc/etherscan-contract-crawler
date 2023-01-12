// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lil Lovers: First Edition 1/1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    Happy Anniversary. I love you Llandy <3    //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract love is ERC721Creator {
    constructor() ERC721Creator("Lil Lovers: First Edition 1/1", "love") {}
}