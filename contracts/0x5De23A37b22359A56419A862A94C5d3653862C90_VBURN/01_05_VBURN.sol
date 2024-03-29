// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Verified Burners by b00t
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//    ██    ██ ███████ ██████  ██ ███████ ██ ███████ ██████      ██████  ██    ██ ██████  ███    ██ ███████ ██████  ███████     //
//    ██    ██ ██      ██   ██ ██ ██      ██ ██      ██   ██     ██   ██ ██    ██ ██   ██ ████   ██ ██      ██   ██ ██          //
//    ██    ██ █████   ██████  ██ █████   ██ █████   ██   ██     ██████  ██    ██ ██████  ██ ██  ██ █████   ██████  ███████     //
//     ██  ██  ██      ██   ██ ██ ██      ██ ██      ██   ██     ██   ██ ██    ██ ██   ██ ██  ██ ██ ██      ██   ██      ██     //
//      ████   ███████ ██   ██ ██ ██      ██ ███████ ██████      ██████   ██████  ██   ██ ██   ████ ███████ ██   ██ ███████     //
//                                                                                                                              //
//                                                                                                                              //
//    ██████  ██    ██     ██████   ██████   ██████  ████████     █████  ██████  ████████                                       //
//    ██   ██  ██  ██      ██   ██ ██  ████ ██  ████    ██       ██   ██ ██   ██    ██                                          //
//    ██████    ████       ██████  ██ ██ ██ ██ ██ ██    ██       ███████ ██████     ██                                          //
//    ██   ██    ██        ██   ██ ████  ██ ████  ██    ██       ██   ██ ██   ██    ██                                          //
//    ██████     ██        ██████   ██████   ██████     ██    ██ ██   ██ ██   ██    ██                                          //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VBURN is ERC721Creator {
    constructor() ERC721Creator("Verified Burners by b00t", "VBURN") {}
}