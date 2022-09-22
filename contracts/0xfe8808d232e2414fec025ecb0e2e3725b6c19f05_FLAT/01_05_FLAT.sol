// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: flat
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    ███████ ██       █████  ████████     //
//    ██      ██      ██   ██    ██        //
//    █████   ██      ███████    ██        //
//    ██      ██      ██   ██    ██        //
//    ██      ███████ ██   ██    ██        //
//                                         //
//                                         //
/////////////////////////////////////////////


contract FLAT is ERC721Creator {
    constructor() ERC721Creator("flat", "FLAT") {}
}