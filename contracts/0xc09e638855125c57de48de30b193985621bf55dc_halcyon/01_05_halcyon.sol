// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Halcyon
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//      _   _       _                            //
//     | | | | __ _| | ___ _   _  ___  _ __      //
//     | |_| |/ _` | |/ __| | | |/ _ \| '_ \     //
//     |  _  | (_| | | (__| |_| | (_) | | | |    //
//     |_| |_|\__,_|_|\___|\__, |\___/|_| |_|    //
//                         |___/                 //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract halcyon is ERC1155Creator {
    constructor() ERC1155Creator("Halcyon", "halcyon") {}
}