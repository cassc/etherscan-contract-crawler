// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BOB
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    BOB BOB BOB BOB     //
//                        //
//                        //
////////////////////////////


contract BOB is ERC1155Creator {
    constructor() ERC1155Creator("BOB", "BOB") {}
}