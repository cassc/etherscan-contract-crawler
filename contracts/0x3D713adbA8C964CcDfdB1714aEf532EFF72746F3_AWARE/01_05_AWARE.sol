// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mono no Aware | もののあはれ
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//      ■■■■■■■■■■■■      //
//     ■■■■■■■■ ■ ■■■     //
//     ■■■■■■■■  ■■■■     //
//     ■■■■■■■  ■   ■     //
//     ■■■■■       ■■     //
//         ■■■■     ■     //
//         ■■■■■ ■■■■     //
//     ■  ■■■■■■■■■■■     //
//     ■■■■■■■■ ■■■■■     //
//     ■■■■    ■■■■■■     //
//       ■     ■■■■■■     //
//     ■■   ■ ■■■■■■■     //
//     ■■■■ ■ ■■■■■■■     //
//      ■■■ ■ ■■■■■■      //
//                        //
//                        //
////////////////////////////


contract AWARE is ERC721Creator {
    constructor() ERC721Creator(unicode"Mono no Aware | もののあはれ", "AWARE") {}
}