// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Form of Thought
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//    █▀▀ █▀█ █▀█ █▀▄▀█   █▀█ █▀▀    //
//    █▀░ █▄█ █▀▄ █░▀░█   █▄█ █▀░    //
//                                   //
//    ▀█▀ █░█ █▀█ █░█ █▀▀ █░█ ▀█▀    //
//    ░█░ █▀█ █▄█ █▄█ █▄█ █▀█ ░█░    //
//                                   //
//                                   //
///////////////////////////////////////


contract FORM is ERC721Creator {
    constructor() ERC721Creator("The Form of Thought", "FORM") {}
}