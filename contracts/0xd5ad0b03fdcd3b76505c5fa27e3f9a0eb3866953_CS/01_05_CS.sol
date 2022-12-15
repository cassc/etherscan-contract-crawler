// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Campfire Stories
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//    _                _            __                          //
//     /   _. ._ _  ._ _|_ o ._ _    (_ _|_  _  ._ o  _   _     //
//     \_ (_| | | | |_) |  | | (/_   __) |_ (_) |  | (/_ _>     //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract CS is ERC721Creator {
    constructor() ERC721Creator("Campfire Stories", "CS") {}
}