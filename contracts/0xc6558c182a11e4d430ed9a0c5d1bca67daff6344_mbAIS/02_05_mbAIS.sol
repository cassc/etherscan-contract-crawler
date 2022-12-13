// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: All Is Serene
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//    ▄▀█ █░░ █░░   █ █▀   █▀ █▀▀ █▀█ █▀▀ █▄░█ █▀▀    //
//    █▀█ █▄▄ █▄▄   █ ▄█   ▄█ ██▄ █▀▄ ██▄ █░▀█ ██▄    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract mbAIS is ERC721Creator {
    constructor() ERC721Creator("All Is Serene", "mbAIS") {}
}