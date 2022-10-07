// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ShonaMcDermott
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//                                                   //
//    ███████ ██   ██  ██████  ███    ██  █████      //
//    ██      ██   ██ ██    ██ ████   ██ ██   ██     //
//    ███████ ███████ ██    ██ ██ ██  ██ ███████     //
//         ██ ██   ██ ██    ██ ██  ██ ██ ██   ██     //
//    ███████ ██   ██  ██████  ██   ████ ██   ██     //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract SMcD is ERC721Creator {
    constructor() ERC721Creator("ShonaMcDermott", "SMcD") {}
}