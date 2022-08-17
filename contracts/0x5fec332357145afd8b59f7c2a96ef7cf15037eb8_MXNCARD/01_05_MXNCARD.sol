// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mxnster Cards
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//    ███    ███ ██   ██ ███    ██ ███████ ████████ ███████ ██████       ██████  █████  ██████  ██████  ███████     //
//    ████  ████  ██ ██  ████   ██ ██         ██    ██      ██   ██     ██      ██   ██ ██   ██ ██   ██ ██          //
//    ██ ████ ██   ███   ██ ██  ██ ███████    ██    █████   ██████      ██      ███████ ██████  ██   ██ ███████     //
//    ██  ██  ██  ██ ██  ██  ██ ██      ██    ██    ██      ██   ██     ██      ██   ██ ██   ██ ██   ██      ██     //
//    ██      ██ ██   ██ ██   ████ ███████    ██    ███████ ██   ██      ██████ ██   ██ ██   ██ ██████  ███████     //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MXNCARD is ERC721Creator {
    constructor() ERC721Creator("Mxnster Cards", "MXNCARD") {}
}