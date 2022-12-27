// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Morphosis in Abstract Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//      \  |    \       \       //
//     |\/ |   _ \     _ \      //
//     |   |  ___ \   ___ \     //
//    _|  _|_/    _\_/    _\    //
//                              //
//                              //
//////////////////////////////////


contract MAA is ERC721Creator {
    constructor() ERC721Creator("Morphosis in Abstract Art", "MAA") {}
}