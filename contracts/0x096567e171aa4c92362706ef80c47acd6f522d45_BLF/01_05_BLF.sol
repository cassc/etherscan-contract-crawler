// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blue Feelings
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//      ____  _      ______     //
//     |  _ \| |    |  ____|    //
//     | |_) | |    | |__       //
//     |  _ <| |    |  __|      //
//     | |_) | |____| |         //
//     |____/|______|_|         //
//                              //
//                              //
//                              //
//                              //
//                              //
//////////////////////////////////


contract BLF is ERC721Creator {
    constructor() ERC721Creator("Blue Feelings", "BLF") {}
}