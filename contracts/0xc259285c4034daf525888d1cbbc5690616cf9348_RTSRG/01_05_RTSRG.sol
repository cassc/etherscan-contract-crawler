// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Artserge
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//           db                                                                                              //
//          d88b                      ,d                                                                     //
//         d8'`8b                     88                                                                     //
//        d8'  `8b      8b,dPPYba,  MM88MMM  ,adPPYba,   ,adPPYba,  8b,dPPYba,   ,adPPYb,d8   ,adPPYba,      //
//       d8YaaaaY8b     88P'   "Y8    88     I8[    ""  a8P_____88  88P'   "Y8  a8"    `Y88  a8P_____88      //
//      d8""""""""8b    88            88      `"Y8ba,   8PP"""""""  88          8b       88  8PP"""""""      //
//     d8'        `8b   88            88,    aa    ]8I  "8b,   ,aa  88          "8a,   ,d88  "8b,   ,aa      //
//    d8'          `8b  88            "Y888  `"YbbdP"'   `"Ybbd8"'  88           `"YbbdP"Y8   `"Ybbd8"'      //
//                                                                               aa,    ,88                  //
//                                                                                "Y8bbdP"                   //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RTSRG is ERC721Creator {
    constructor() ERC721Creator("Artserge", "RTSRG") {}
}