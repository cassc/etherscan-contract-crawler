// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Medusa Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//    ███    ███ ███████ ██████  ██    ██ ███████  █████      //
//    ████  ████ ██      ██   ██ ██    ██ ██      ██   ██     //
//    ██ ████ ██ █████   ██   ██ ██    ██ ███████ ███████     //
//    ██  ██  ██ ██      ██   ██ ██    ██      ██ ██   ██     //
//    ██      ██ ███████ ██████   ██████  ███████ ██   ██     //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract SMMM is ERC721Creator {
    constructor() ERC721Creator("Medusa Editions", "SMMM") {}
}