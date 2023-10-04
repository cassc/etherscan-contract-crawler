// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Unscripted
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//                         //
//      _    _   ____      //
//     | |  | | |  _ \     //
//     | |__| | | |_) |    //
//     |  __  | |  _ <     //
//     | |  | | | |_) |    //
//     |_|  |_| |____/     //
//                         //
//                         //
//                         //
//                         //
//                         //
/////////////////////////////


contract USCRP is ERC721Creator {
    constructor() ERC721Creator("Unscripted", "USCRP") {}
}