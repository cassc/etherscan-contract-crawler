// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CRANIUM  II
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//     ██████ ██████  ███    ██ ███    ███     //
//    ██      ██   ██ ████   ██ ████  ████     //
//    ██      ██████  ██ ██  ██ ██ ████ ██     //
//    ██      ██   ██ ██  ██ ██ ██  ██  ██     //
//     ██████ ██   ██ ██   ████ ██      ██     //
//                                             //
//                                             //
//                                             //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract CRNM is ERC721Creator {
    constructor() ERC721Creator("CRANIUM  II", "CRNM") {}
}