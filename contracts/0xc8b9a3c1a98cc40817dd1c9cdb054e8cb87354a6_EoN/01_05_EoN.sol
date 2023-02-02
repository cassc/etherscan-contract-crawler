// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Everything or Nothing
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    ███████  ██████  ███    ██     //
//    ██      ██    ██ ████   ██     //
//    █████   ██    ██ ██ ██  ██     //
//    ██      ██    ██ ██  ██ ██     //
//    ███████  ██████  ██   ████     //
//                                   //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract EoN is ERC721Creator {
    constructor() ERC721Creator("Everything or Nothing", "EoN") {}
}