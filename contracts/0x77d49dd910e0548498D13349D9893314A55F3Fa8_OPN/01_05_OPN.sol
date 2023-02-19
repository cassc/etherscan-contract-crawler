// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Open
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//                      //
//     () |^ [- |\|     //
//                      //
//          by          //
//                      //
//        J'erre        //
//                      //
//                      //
//                      //
//////////////////////////


contract OPN is ERC1155Creator {
    constructor() ERC1155Creator("Open", "OPN") {}
}