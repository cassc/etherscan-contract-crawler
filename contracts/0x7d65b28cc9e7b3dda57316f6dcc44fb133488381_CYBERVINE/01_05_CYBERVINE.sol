// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CyberVine
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//                                                                              //
//    ██████  ██   ██ ██    ██  ██████  ██ ██████   ██████  ██      ██          //
//    ██   ██ ██   ██  ██  ██  ██       ██ ██   ██ ██    ██ ██      ██          //
//    ██████  ███████   ████   ██   ███ ██ ██   ██ ██    ██ ██      ██          //
//    ██      ██   ██    ██    ██    ██ ██ ██   ██ ██    ██ ██      ██          //
//    ██      ██   ██    ██     ██████  ██ ██████   ██████  ███████ ███████     //
//                                                                              //
//                                                                              //
//    CyberVine, a Mini-Collection under Phygidoll                              //
//    Created by Stephanie Valle, cleverglitch.eth                              //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract CYBERVINE is ERC721Creator {
    constructor() ERC721Creator("CyberVine", "CYBERVINE") {}
}