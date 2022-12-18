// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ALFA DAF
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                                   //
//        ___    __    _________     //
//       /   |  / /   / ____/   |    //
//      / /| | / /   / /_  / /| |    //
//     / ___ |/ /___/ __/ / ___ |    //
//    /_/  |_/_____/_/   /_/  |_|    //
//                                   //
//                                   //
//                                   //
//                                   //
///////////////////////////////////////


contract ALFA is ERC1155Creator {
    constructor() ERC1155Creator("ALFA DAF", "ALFA") {}
}