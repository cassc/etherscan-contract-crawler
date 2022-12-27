// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gül Yıldız
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//                                                                                 //
//       _____ _    _ _       __     _______ _      _____ _____ ______             //
//      / ____| |  | | |      \ \   / /_   _| |    |  __ \_   _|___  /             //
//     | |  __| |  | | |       \ \_/ /  | | | |    | |  | || |    / /              //
//     | | |_ | |  | | |        \   /   | | | |    | |  | || |   / /               //
//     | |__| | |__| | |____     | |   _| |_| |____| |__| || |_ / /__              //
//      \_____|\____/|______|    |_|  |_____|______|_____/_____/_____|             //
//                                                                                 //
//                                                                                 //
//                                                                                 //
//    Fujifilm Official X Photographer, Multidisciplinary Artist, Cinema Writer    //
//    https://twitter.com/gulyildizart                                             //
//    https://www.gulyildiz.net/                                                   //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////


contract GLYLZ is ERC1155Creator {
    constructor() ERC1155Creator(unicode"Gül Yıldız", "GLYLZ") {}
}