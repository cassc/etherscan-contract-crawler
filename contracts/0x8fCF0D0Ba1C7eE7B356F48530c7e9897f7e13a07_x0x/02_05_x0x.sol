// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0x
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//      ______               //
//     /      \              //
//    |  ▓▓▓▓▓▓\__    __     //
//    | ▓▓▓\| ▓▓  \  /  \    //
//    | ▓▓▓▓\ ▓▓\▓▓\/  ▓▓    //
//    | ▓▓\▓▓\▓▓ >▓▓  ▓▓     //
//    | ▓▓_\▓▓▓▓/  ▓▓▓▓\     //
//     \▓▓  \▓▓▓  ▓▓ \▓▓\    //
//      \▓▓▓▓▓▓ \▓▓   \▓▓    //
//                           //
//                           //
///////////////////////////////


contract x0x is ERC721Creator {
    constructor() ERC721Creator("0x", "x0x") {}
}