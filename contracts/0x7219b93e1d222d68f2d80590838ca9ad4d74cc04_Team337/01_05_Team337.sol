// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: #3つの符号
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//                                                                  //
//     ■■■■■■■■                           ■■■■    ■■■■   ■■■■■■     //
//        ■                              ■   ■■  ■   ■■       ■     //
//        ■      ■■■■   ■■■   ■■■■  ■■        ■       ■      ■      //
//        ■     ■■  ■  ■   ■  ■■  ■■  ■      ■       ■       ■      //
//        ■     ■   ■■     ■  ■   ■   ■    ■■■     ■■■      ■       //
//        ■     ■■■■■■ ■■■■■  ■   ■   ■      ■■      ■■     ■       //
//        ■     ■      ■   ■  ■   ■   ■       ■       ■    ■        //
//        ■     ■■     ■  ■■  ■   ■   ■  ■   ■■  ■   ■■    ■        //
//        ■      ■■■■  ■■■■■  ■   ■   ■   ■■■■    ■■■■    ■■        //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract Team337 is ERC721Creator {
    constructor() ERC721Creator(unicode"#3つの符号", "Team337") {}
}