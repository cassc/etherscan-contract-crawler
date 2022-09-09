// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EXGOMI Machina X Mk 1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//    ███████ ██   ██  ██████   ██████  ███    ███ ██     //
//    ██       ██ ██  ██       ██    ██ ████  ████ ██     //
//    █████     ███   ██   ███ ██    ██ ██ ████ ██ ██     //
//    ██       ██ ██  ██    ██ ██    ██ ██  ██  ██ ██     //
//    ███████ ██   ██  ██████   ██████  ██      ██ ██     //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract EXGOMI is ERC721Creator {
    constructor() ERC721Creator("EXGOMI Machina X Mk 1", "EXGOMI") {}
}