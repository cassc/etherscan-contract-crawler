// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BREAKFASTKING
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////
//                               //
//                               //
//                               //
//      /$$$$$$  /$$      /$$    //
//     /$$__  $$| $$$    /$$$    //
//    | $$  \__/| $$$$  /$$$$    //
//    | $$ /$$$$| $$ $$/$$ $$    //
//    | $$|_  $$| $$  $$$| $$    //
//    | $$  \ $$| $$\  $ | $$    //
//    |  $$$$$$/| $$ \/  | $$    //
//     \______/ |__/     |__/    //
//                               //
//                               //
//                               //
//                               //
///////////////////////////////////


contract BKXYZ is ERC1155Creator {
    constructor() ERC1155Creator("BREAKFASTKING", "BKXYZ") {}
}