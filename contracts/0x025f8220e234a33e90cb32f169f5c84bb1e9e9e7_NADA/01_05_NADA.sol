// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nothing by NADA
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    NOTHING TO SEE HERE    //
//                           //
//                           //
///////////////////////////////


contract NADA is ERC1155Creator {
    constructor() ERC1155Creator("Nothing by NADA", "NADA") {}
}