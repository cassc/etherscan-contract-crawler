// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lujan
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//    ██      ██    ██      ██  █████  ███    ██    //
//    ██      ██    ██      ██ ██   ██ ████   ██    //
//    ██      ██    ██      ██ ███████ ██ ██  ██    //
//    ██      ██    ██ ██   ██ ██   ██ ██  ██ ██    //
//    ███████  ██████   █████  ██   ██ ██   ████    //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract Lujan is ERC721Creator {
    constructor() ERC721Creator("Lujan", "Lujan") {}
}