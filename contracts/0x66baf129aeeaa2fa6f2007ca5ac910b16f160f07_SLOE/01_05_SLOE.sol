// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stop launching open editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    Launch deez nutz    //
//                        //
//                        //
////////////////////////////


contract SLOE is ERC721Creator {
    constructor() ERC721Creator("Stop launching open editions", "SLOE") {}
}