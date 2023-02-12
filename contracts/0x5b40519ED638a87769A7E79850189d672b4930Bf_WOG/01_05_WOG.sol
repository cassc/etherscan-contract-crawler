// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: World of Ghosts
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//     ____ ____ ____ ____ ____ ____     //
//    ||G |||h |||o |||s |||t |||s ||    //
//    ||__|||__|||__|||__|||__|||__||    //
//    |/__\|/__\|/__\|/__\|/__\|/__\|    //
//                                       //
//                                       //
///////////////////////////////////////////


contract WOG is ERC1155Creator {
    constructor() ERC1155Creator("World of Ghosts", "WOG") {}
}