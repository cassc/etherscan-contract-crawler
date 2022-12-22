// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vlada Glinskaya
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

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


contract VG is ERC1155Creator {
    constructor() ERC1155Creator("Vlada Glinskaya", "VG") {}
}