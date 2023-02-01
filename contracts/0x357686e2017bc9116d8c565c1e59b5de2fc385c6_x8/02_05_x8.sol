// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: xEight
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//          _____ _       _     _       //
//         |  ___(_)     | |   | |      //
//    __  _| |__  _  __ _| |__ | |_     //
//    \ \/ /  __|| |/ _` | '_ \| __|    //
//     >  <| |___| | (_| | | | | |_     //
//    /_/\_\____/|_|\__, |_| |_|\__|    //
//                   __/ |              //
//                  |___/               //
//                                      //
//                                      //
//////////////////////////////////////////


contract x8 is ERC1155Creator {
    constructor() ERC1155Creator("xEight", "x8") {}
}