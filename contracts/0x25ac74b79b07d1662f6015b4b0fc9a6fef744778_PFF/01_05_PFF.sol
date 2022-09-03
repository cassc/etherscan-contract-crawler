// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PFF Immortal
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//      _____  ______ ______     //
//     |  __ \|  ____|  ____|    //
//     | |__) | |__  | |__       //
//     |  ___/|  __| |  __|      //
//     | |    | |    | |         //
//     |_|    |_|    |_|         //
//                               //
//                               //
///////////////////////////////////


contract PFF is ERC721Creator {
    constructor() ERC721Creator("PFF Immortal", "PFF") {}
}