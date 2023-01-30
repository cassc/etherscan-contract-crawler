// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SuddenBoom
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    A sudden Boom in your life.    //
//                                   //
//                                   //
///////////////////////////////////////


contract SDB is ERC1155Creator {
    constructor() ERC1155Creator("SuddenBoom", "SDB") {}
}