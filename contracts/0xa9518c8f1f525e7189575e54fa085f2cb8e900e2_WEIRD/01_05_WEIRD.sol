// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Weird Imaginations
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    ██     ██ ███████ ██ ██████  ██████      //
//    ██     ██ ██      ██ ██   ██ ██   ██     //
//    ██  █  ██ █████   ██ ██████  ██   ██     //
//    ██ ███ ██ ██      ██ ██   ██ ██   ██     //
//     ███ ███  ███████ ██ ██   ██ ██████      //
//                                             //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract WEIRD is ERC721Creator {
    constructor() ERC721Creator("Weird Imaginations", "WEIRD") {}
}