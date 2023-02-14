// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FLYING  FUNDOSHI
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//    ______________________    //
//    \_   _____/\_   _____/    //
//     |    __)   |    __)      //
//     |     \    |     \       //
//     \___  /    \___  /       //
//         \/         \/        //
//                              //
//                              //
//                              //
//////////////////////////////////


contract FF is ERC1155Creator {
    constructor() ERC1155Creator("FLYING  FUNDOSHI", "FF") {}
}