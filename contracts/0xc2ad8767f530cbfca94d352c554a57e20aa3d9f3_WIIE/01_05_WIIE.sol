// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Whatisiana Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    by whatisiana    //
//                     //
//                     //
/////////////////////////


contract WIIE is ERC1155Creator {
    constructor() ERC1155Creator("Whatisiana Editions", "WIIE") {}
}