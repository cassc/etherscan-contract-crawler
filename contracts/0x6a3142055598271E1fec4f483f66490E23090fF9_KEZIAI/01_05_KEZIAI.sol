// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KEZIAI
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//                                              //
//    ██   ██ ███████ ███████ ██  █████  ██     //
//    ██  ██  ██         ███  ██ ██   ██ ██     //
//    █████   █████     ███   ██ ███████ ██     //
//    ██  ██  ██       ███    ██ ██   ██ ██     //
//    ██   ██ ███████ ███████ ██ ██   ██ ██     //
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract KEZIAI is ERC721Creator {
    constructor() ERC721Creator("KEZIAI", "KEZIAI") {}
}