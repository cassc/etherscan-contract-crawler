// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Zpaste 1/1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//      ____                __         //
//     /_  / ___  ___ ____ / /____     //
//      / /_/ _ \/ _ `(_-</ __/ -_)    //
//     /___/ .__/\_,_/___/\__/\__/     //
//        /_/                          //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract ZP1 is ERC721Creator {
    constructor() ERC721Creator("Zpaste 1/1", "ZP1") {}
}