// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Listen to me
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                   //
//                                                                                                   //
//    ██      ██ ███████ ████████ ███████ ███    ██     ████████  ██████      ███    ███ ███████     //
//    ██      ██ ██         ██    ██      ████   ██        ██    ██    ██     ████  ████ ██          //
//    ██      ██ ███████    ██    █████   ██ ██  ██        ██    ██    ██     ██ ████ ██ █████       //
//    ██      ██      ██    ██    ██      ██  ██ ██        ██    ██    ██     ██  ██  ██ ██          //
//    ███████ ██ ███████    ██    ███████ ██   ████        ██     ██████      ██      ██ ███████     //
//                                                                                                   //
//                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////


contract LTM is ERC721Creator {
    constructor() ERC721Creator("Listen to me", "LTM") {}
}