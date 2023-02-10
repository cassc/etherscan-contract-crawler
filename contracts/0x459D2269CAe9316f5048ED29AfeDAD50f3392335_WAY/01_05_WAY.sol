// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: the only way
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//     ▄▀▀▄    ▄▀▀▄  ▄▀▀█▄   ▄▀▀▄ ▀▀▄    //
//    █   █    ▐  █ ▐ ▄▀ ▀▄ █   ▀▄ ▄▀    //
//    ▐  █        █   █▄▄▄█ ▐     █      //
//      █   ▄    █   ▄▀   █       █      //
//       ▀▄▀ ▀▄ ▄▀  █   ▄▀      ▄▀       //
//             ▀    ▐   ▐       █        //
//                              ▐        //
//                                       //
//    by pale kirill                     //
//                                       //
//                                       //
///////////////////////////////////////////


contract WAY is ERC721Creator {
    constructor() ERC721Creator("the only way", "WAY") {}
}