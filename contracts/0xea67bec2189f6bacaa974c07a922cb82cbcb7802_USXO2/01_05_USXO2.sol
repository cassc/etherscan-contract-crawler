// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: underscore_2
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    ██    ██ ███████ ██   ██  ██████  ██████      //
//    ██    ██ ██       ██ ██  ██    ██      ██     //
//    ██    ██ ███████   ███   ██    ██  █████      //
//    ██    ██      ██  ██ ██  ██    ██ ██          //
//     ██████  ███████ ██   ██  ██████  ███████     //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract USXO2 is ERC721Creator {
    constructor() ERC721Creator("underscore_2", "USXO2") {}
}