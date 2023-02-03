// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sewer Checks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    Sewer Pass    //
//    Checks        //
//    Renga         //
//    Opepen        //
//    TAOS          //
//                  //
//                  //
//////////////////////


contract SC is ERC1155Creator {
    constructor() ERC1155Creator("Sewer Checks", "SC") {}
}