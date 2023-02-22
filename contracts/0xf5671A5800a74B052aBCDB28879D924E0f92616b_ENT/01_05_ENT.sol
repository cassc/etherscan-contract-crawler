// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: entto
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//                                 //
//                _   _            //
//               | | | |           //
//      ___ _ __ | |_| |_ ___      //
//     / _ \ '_ \| __| __/ _ \     //
//    |  __/ | | | |_| || (_) |    //
//     \___|_| |_|\__|\__\___/     //
//                                 //
//                                 //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract ENT is ERC721Creator {
    constructor() ERC721Creator("entto", "ENT") {}
}