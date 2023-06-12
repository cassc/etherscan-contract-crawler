// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: coers
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//     ██████  ██████  ███████ ██████  ███████     //
//    ██      ██    ██ ██      ██   ██ ██          //
//    ██      ██    ██ █████   ██████  ███████     //
//    ██      ██    ██ ██      ██   ██      ██     //
//     ██████  ██████  ███████ ██   ██ ███████     //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract CRS is ERC721Creator {
    constructor() ERC721Creator("coers", "CRS") {}
}