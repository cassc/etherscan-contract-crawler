// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: N8
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    ███    ██  █████      //
//    ████   ██ ██   ██     //
//    ██ ██  ██  █████      //
//    ██  ██ ██ ██   ██     //
//    ██   ████  █████      //
//                          //
//                          //
//                          //
//                          //
//                          //
//                          //
//////////////////////////////


contract N8 is ERC721Creator {
    constructor() ERC721Creator("N8", "N8") {}
}