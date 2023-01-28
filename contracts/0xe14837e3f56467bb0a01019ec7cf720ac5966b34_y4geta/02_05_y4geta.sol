// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OEs/shigetayusuke
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//                        //
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
//                        //
//                        //
//                        //
////////////////////////////


contract y4geta is ERC1155Creator {
    constructor() ERC1155Creator("OEs/shigetayusuke", "y4geta") {}
}