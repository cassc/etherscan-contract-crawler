// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: diegoprime inky.art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//      _       _                      _       //
//     (_)_ __ | | ___   _   __ _ _ __| |_     //
//     | | '_ \| |/ / | | | / _` | '__| __|    //
//     | | | | |   <| |_| || (_| | |  | |_     //
//     |_|_| |_|_|\_\\__, (_)__,_|_|   \__|    //
//                   |___/                     //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract INKY is ERC721Creator {
    constructor() ERC721Creator("diegoprime inky.art", "INKY") {}
}