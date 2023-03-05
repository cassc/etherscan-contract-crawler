// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hybrids
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    (((((((((((((((oooooooo))))))))))))))))    //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract hyb is ERC721Creator {
    constructor() ERC721Creator("Hybrids", "hyb") {}
}