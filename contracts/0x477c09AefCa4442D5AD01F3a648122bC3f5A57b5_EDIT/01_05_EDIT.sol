// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//      _        _             _         //
//     | |_  ___(_)______ _ _ ( )___     //
//     | ' \/ _ \ |_ / _ \ ' \|/(_-<     //
//     |_||_\___/_/__\___/_||_| /__/     //
//      ___ __| (_) |_(_)___ _ _  ___    //
//     / -_) _` | |  _| / _ \ ' \(_-<    //
//     \___\__,_|_|\__|_\___/_||_/__/    //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract EDIT is ERC721Creator {
    constructor() ERC721Creator("Editions", "EDIT") {}
}