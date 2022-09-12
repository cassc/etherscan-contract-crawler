// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: In.Squares
/// @author: manifold.xyz

import "./ERC721Creator.sol";

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


contract INSQUARS is ERC721Creator {
    constructor() ERC721Creator("In.Squares", "INSQUARS") {}
}