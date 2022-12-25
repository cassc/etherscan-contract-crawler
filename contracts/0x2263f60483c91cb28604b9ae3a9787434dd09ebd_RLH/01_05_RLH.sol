// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RALIAH
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//      _____   _       _    _     //
//     |  __ \ | |     | |  | |    //
//     | |__) || |     | |__| |    //
//     |  _  / | |     |  __  |    //
//     | | \ \ | |____ | |  | |    //
//     |_|  \_\|______||_|  |_|    //
//                                 //
//                                 //
//                                 //
//                                 //
/////////////////////////////////////


contract RLH is ERC721Creator {
    constructor() ERC721Creator("RALIAH", "RLH") {}
}