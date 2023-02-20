// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Follow the white rabbit.
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    Follow the white rabbit.    //
//                                //
//                                //
////////////////////////////////////


contract FTWR is ERC1155Creator {
    constructor() ERC1155Creator("Follow the white rabbit.", "FTWR") {}
}