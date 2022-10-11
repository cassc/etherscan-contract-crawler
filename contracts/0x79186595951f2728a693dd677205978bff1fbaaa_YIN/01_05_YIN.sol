// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Digital Art Pieces ‘22
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    Yinkore Contract    //
//                        //
//                        //
////////////////////////////


contract YIN is ERC721Creator {
    constructor() ERC721Creator(unicode"Digital Art Pieces ‘22", "YIN") {}
}