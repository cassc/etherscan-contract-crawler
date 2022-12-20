// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pages
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    ██████   █████   ██████  ███████ ███████     //
//    ██   ██ ██   ██ ██       ██      ██          //
//    ██████  ███████ ██   ███ █████   ███████     //
//    ██      ██   ██ ██    ██ ██           ██     //
//    ██      ██   ██  ██████  ███████ ███████     //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract P10 is ERC721Creator {
    constructor() ERC721Creator("Pages", "P10") {}
}