// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: my favourite muse
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    (((((((((((((((oooooooo))))))))))))))))    //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract mfm is ERC721Creator {
    constructor() ERC721Creator("my favourite muse", "mfm") {}
}