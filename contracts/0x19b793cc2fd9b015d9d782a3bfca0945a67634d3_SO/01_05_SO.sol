// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SIMPLE OBJECTS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                                          //
//      _          _      _    _   _   _   _   _  __  _     //
//     /_` / /|,/ /_/ /  /_`  / / /_)   / /_` / ` /  /_`    //
//    ._/ / /  / /   /_,/_,  /_/ /_) (_/ /_, /_, /  ._/     //
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract SO is ERC721Creator {
    constructor() ERC721Creator("SIMPLE OBJECTS", "SO") {}
}