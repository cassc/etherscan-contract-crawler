// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: We Are Your Overlords
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//    █░█░█ ▄▀█ █▀█ █▀ █▄▀ █░█ █░░ █░░    //
//    ▀▄▀▄▀ █▀█ █▀▄ ▄█ █░█ █▄█ █▄▄ █▄▄    //
//                                        //
//                                        //
////////////////////////////////////////////


contract Warskull is ERC1155Creator {
    constructor() ERC1155Creator("We Are Your Overlords", "Warskull") {}
}