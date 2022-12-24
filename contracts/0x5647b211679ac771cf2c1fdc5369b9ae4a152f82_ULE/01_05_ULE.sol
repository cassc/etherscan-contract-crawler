// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ULÉ
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    ##  ###  ####     ### ###      //
//    ##   ##   ##       ##  ##      //
//    ##   ##   ##       ##          //
//    ##   ##   ##       ## ##       //
//    ##   ##   ##       ##          //
//    ##   ##   ##  ##   ##  ##      //
//     ## ##   ### ###  ### ###      //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract ULE is ERC721Creator {
    constructor() ERC721Creator(unicode"ULÉ", "ULE") {}
}