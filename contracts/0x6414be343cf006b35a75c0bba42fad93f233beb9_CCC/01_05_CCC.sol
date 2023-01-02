// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CC Coin
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//                          //
//     ____  ____  ____     //
//    /   _\/   _\/   _\    //
//    |  /  |  /  |  /      //
//    |  \__|  \__|  \_     //
//    \____/\____/\____/    //
//                          //
//                          //
//                          //
//                          //
//////////////////////////////


contract CCC is ERC721Creator {
    constructor() ERC721Creator("CC Coin", "CCC") {}
}