// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Light
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    BYFARAH Contract    //
//                        //
//                        //
////////////////////////////


contract LG is ERC721Creator {
    constructor() ERC721Creator("Light", "LG") {}
}