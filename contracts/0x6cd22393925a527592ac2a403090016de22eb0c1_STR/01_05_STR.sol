// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stories
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//     _______ _______  _____   ______ _____ _______ _______    //
//     |______    |    |     | |_____/   |   |______ |______    //
//     ______|    |    |_____| |    \_ __|__ |______ ______|    //
//                                                              //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract STR is ERC721Creator {
    constructor() ERC721Creator("Stories", "STR") {}
}