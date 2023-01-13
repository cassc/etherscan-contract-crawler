// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Black Square
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    by whatisiana    //
//                     //
//                     //
/////////////////////////


contract BLCK is ERC1155Creator {
    constructor() ERC1155Creator("Black Square", "BLCK") {}
}