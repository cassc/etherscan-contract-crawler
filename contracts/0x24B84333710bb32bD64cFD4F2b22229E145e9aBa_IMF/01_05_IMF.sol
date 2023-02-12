// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Imaginary Friends
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//     __      _____________    //
//    /  \    /  \_   _____/    //
//    \   \/\/   /|    __)      //
//     \        / |     \       //
//      \__/\  /  \___  /       //
//           \/       \/        //
//                              //
//                              //
//                              //
//////////////////////////////////


contract IMF is ERC1155Creator {
    constructor() ERC1155Creator("Imaginary Friends", "IMF") {}
}