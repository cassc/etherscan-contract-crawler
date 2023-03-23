// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tokens N' Tunes Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//          __       __            __          //
//         |__) \ / |__) | |    | /__`         //
//         |     |  |  \ | |___ | .__/         //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract TNT is ERC1155Creator {
    constructor() ERC1155Creator("Tokens N' Tunes Editions", "TNT") {}
}