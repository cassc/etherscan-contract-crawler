// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Donnerss Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    ▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼    //
//    ▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼    //
//    ▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼    //
//    ▼△▼                       ▼△▼    //
//    ▼△▼       donnerss        ▼△▼    //
//    ▼△▼                       ▼△▼    //
//    ▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼    //
//    ▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼    //
//    ▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼△▼    //
//                                     //
//                                     //
/////////////////////////////////////////


contract makemoreart is ERC1155Creator {
    constructor() ERC1155Creator("Donnerss Editions", "makemoreart") {}
}