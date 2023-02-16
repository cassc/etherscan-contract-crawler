// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Reasoned Art x (un)fair
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//       __         __   __      _          //
//      / /         \ \ / _|    (_)         //
//     | |_   _ _ __ | | |_ __ _ _ _ __     //
//     | | | | | '_ \| |  _/ _` | | '__|    //
//     | | |_| | | | | | || (_| | | |       //
//     | |\__,_|_| |_| |_| \__,_|_|_|       //
//      \_\         /_/                     //
//                                          //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract UNFAIR is ERC1155Creator {
    constructor() ERC1155Creator("Reasoned Art x (un)fair", "UNFAIR") {}
}