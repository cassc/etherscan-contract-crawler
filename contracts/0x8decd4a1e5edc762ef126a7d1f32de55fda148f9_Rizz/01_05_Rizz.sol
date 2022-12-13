// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rizzle Block
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////
//                               //
//                               //
//                               //
//                               //
//     _____ _         _         //
//    | __  |_|___ ___| |___     //
//    |    -| |- _|- _| | -_|    //
//    |__|__|_|___|___|_|___|    //
//                               //
//                               //
//                               //
//                               //
///////////////////////////////////


contract Rizz is ERC1155Creator {
    constructor() ERC1155Creator("Rizzle Block", "Rizz") {}
}