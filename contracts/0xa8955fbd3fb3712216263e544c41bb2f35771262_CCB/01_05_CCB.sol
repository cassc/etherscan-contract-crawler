// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks Color Blast
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//                                                                                   //
//     CCC h             k             CCC     l             BBBB  l          t      //
//    C    h             k k          C        l             B   B l          t      //
//    C    hhh  eee  ccc kk    ss     C    ooo l ooo rrr     BBBB  l  aa  ss ttt     //
//    C    h  h e e c    k k   s      C    o o l o o r       B   B l a a  s   t      //
//     CCC h  h ee   ccc k  k ss       CCC ooo l ooo r       BBBB  l aaa ss   tt     //
//                                                                                   //
//                                                                                   //
//                                                                                   //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract CCB is ERC1155Creator {
    constructor() ERC1155Creator("Checks Color Blast", "CCB") {}
}