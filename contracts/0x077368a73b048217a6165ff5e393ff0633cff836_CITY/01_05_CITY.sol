// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cityscapes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Cityscapes by indie.    //
//                            //
//                            //
////////////////////////////////


contract CITY is ERC721Creator {
    constructor() ERC721Creator("Cityscapes", "CITY") {}
}