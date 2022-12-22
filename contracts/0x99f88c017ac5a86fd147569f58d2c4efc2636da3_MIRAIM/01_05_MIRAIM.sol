// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: -MIRAI_M-
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    ■■     ■■  ■   ■■■■■     ■■    ■     //
//    ■■     ■■  ■   ■    ■    ■■    ■     //
//    ■■■    ■■  ■   ■    ■    ■ ■   ■     //
//    ■ ■   ■ ■  ■   ■    ■   ■■ ■   ■     //
//    ■ ■■  ■ ■  ■   ■■■■■    ■  ■■  ■     //
//    ■  ■ ■■ ■  ■   ■   ■   ■■   ■  ■     //
//    ■  ■ ■  ■  ■   ■   ■■  ■■■■■■  ■     //
//    ■   ■■  ■  ■   ■    ■  ■    ■■ ■     //
//    ■   ■   ■  ■   ■    ■■■■     ■ ■     //
//                                         //
//                                         //
/////////////////////////////////////////////


contract MIRAIM is ERC1155Creator {
    constructor() ERC1155Creator("-MIRAI_M-", "MIRAIM") {}
}