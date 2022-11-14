// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fantasy Black Holes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Fantasy Black Holes     //
//                            //
//                            //
////////////////////////////////


contract FBH is ERC721Creator {
    constructor() ERC721Creator("Fantasy Black Holes", "FBH") {}
}