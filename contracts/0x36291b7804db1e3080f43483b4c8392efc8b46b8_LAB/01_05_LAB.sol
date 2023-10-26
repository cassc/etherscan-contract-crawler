// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dr.Grinspoon's LAB
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    LAB                //
//    ART                //
//    SOMETIMES MORE     //
//    SOMETIMES LESS     //
//    Process            //
//    ...                //
//    ..                 //
//    .                  //
//                       //
//                       //
///////////////////////////


contract LAB is ERC1155Creator {
    constructor() ERC1155Creator("Dr.Grinspoon's LAB", "LAB") {}
}