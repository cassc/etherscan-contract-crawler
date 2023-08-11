// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nuh Milo 2023
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//                                             //
//                                             //
//    ███    ██ ███    ███ ██████  ██████      //
//    ████   ██ ████  ████      ██      ██     //
//    ██ ██  ██ ██ ████ ██  █████   █████      //
//    ██  ██ ██ ██  ██  ██ ██           ██     //
//    ██   ████ ██      ██ ███████ ██████      //
//                                             //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract NM23 is ERC721Creator {
    constructor() ERC721Creator("Nuh Milo 2023", "NM23") {}
}