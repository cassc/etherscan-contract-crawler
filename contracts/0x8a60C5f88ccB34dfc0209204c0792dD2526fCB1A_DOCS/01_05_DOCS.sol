// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Computer Science (Death of) by BASIIC
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//    ██████   █████  ███████ ██ ██  ██████                                         //
//    ██   ██ ██   ██ ██      ██ ██ ██                                              //
//    ██████  ███████ ███████ ██ ██ ██                                              //
//    ██   ██ ██   ██      ██ ██ ██ ██                                              //
//    ██████  ██   ██ ███████ ██ ██  ██████                                         //
//                                                                                  //
//    DEATH OF COMPUTER SCIENCE, 2023                                               //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract DOCS is ERC721Creator {
    constructor() ERC721Creator("Computer Science (Death of) by BASIIC", "DOCS") {}
}