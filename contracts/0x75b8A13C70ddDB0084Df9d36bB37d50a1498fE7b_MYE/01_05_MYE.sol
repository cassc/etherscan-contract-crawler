// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Michael Yamashita Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//    8b        d8    db         88b           d88         db             //
//     Y8,    ,8P    d88b        888b         d888        d88b            //
//      Y8,  ,8P    d8'`8b       88`8b       d8'88       d8'`8b           //
//       "8aa8"    d8'  `8b      88 `8b     d8' 88      d8'  `8b          //
//        `88'    d8YaaaaY8b     88  `8b   d8'  88     d8YaaaaY8b         //
//         88    d8""""""""8b    88   `8b d8'   88    d8""""""""8b        //
//         88   d8'        `8b   88    `888'    88   d8'        `8b       //
//         88  d8'          `8b  88     `8'     88  d8'          `8b      //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract MYE is ERC721Creator {
    constructor() ERC721Creator("Michael Yamashita Editions", "MYE") {}
}