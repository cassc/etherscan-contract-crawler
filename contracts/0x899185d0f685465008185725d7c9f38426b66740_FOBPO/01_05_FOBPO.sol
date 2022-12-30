// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fobpo
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//                               //
//                               //
//     _____     _               //
//    |   __|___| |_ ___ ___     //
//    |   __| . | . | . | . |    //
//    |__|  |___|___|  _|___|    //
//                  |_|          //
//                               //
//                               //
//                               //
///////////////////////////////////


contract FOBPO is ERC721Creator {
    constructor() ERC721Creator("Fobpo", "FOBPO") {}
}