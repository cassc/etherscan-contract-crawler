// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lost In Moments
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    ██      ██ ███    ███     //
//    ██      ██ ████  ████     //
//    ██      ██ ██ ████ ██     //
//    ██      ██ ██  ██  ██     //
//    ███████ ██ ██      ██     //
//                              //
//                              //
//                              //
//                              //
//                              //
//                              //
//                              //
//                              //
//                              //
//                              //
//                              //
//////////////////////////////////


contract MOMENTS is ERC721Creator {
    constructor() ERC721Creator("Lost In Moments", "MOMENTS") {}
}