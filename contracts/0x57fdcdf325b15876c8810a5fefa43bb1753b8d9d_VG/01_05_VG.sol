// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vlada Glinskaya
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//     /$$    /$$  /$$$$$$     //
//    | $$   | $$ /$$__  $$    //
//    | $$   | $$| $$  \__/    //
//    |  $$ / $$/| $$ /$$$$    //
//     \  $$ $$/ | $$|_  $$    //
//      \  $$$/  | $$  \ $$    //
//       \  $/   |  $$$$$$/    //
//        \_/     \______/     //
//                             //
//                             //
//                             //
//                             //
//                             //
/////////////////////////////////


contract VG is ERC721Creator {
    constructor() ERC721Creator("Vlada Glinskaya", "VG") {}
}