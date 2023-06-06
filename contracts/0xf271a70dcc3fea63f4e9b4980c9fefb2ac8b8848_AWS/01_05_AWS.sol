// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Art Without Borders
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    ARTFREAK'S SPECIAL DROPS    //
//                                //
//                                //
////////////////////////////////////


contract AWS is ERC721Creator {
    constructor() ERC721Creator("Art Without Borders", "AWS") {}
}