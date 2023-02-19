// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Primitive RE Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//                               //
//      _____  _____  ______     //
//     |  __ \|  __ \|  ____|    //
//     | |__) | |__) | |__       //
//     |  ___/|  _  /|  __|      //
//     | |    | | \ \| |____     //
//     |_|    |_|  \_\______|    //
//                               //
//                               //
//                               //
//                               //
//                               //
///////////////////////////////////


contract PRE is ERC721Creator {
    constructor() ERC721Creator("Primitive RE Editions", "PRE") {}
}