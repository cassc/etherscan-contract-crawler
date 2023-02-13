// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: fuma
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//                  //
//        ■         //
//        ■■ ■■     //
//    ■■■■■■■       //
//        ■         //
//     ■■■■■■■      //
//        ■         //
//        ■         //
//     ■■■■■        //
//    ■■  ■■■■      //
//     ■■■■   ■     //
//                  //
//                  //
//                  //
//////////////////////


contract fumaN is ERC1155Creator {
    constructor() ERC1155Creator("fuma", "fumaN") {}
}