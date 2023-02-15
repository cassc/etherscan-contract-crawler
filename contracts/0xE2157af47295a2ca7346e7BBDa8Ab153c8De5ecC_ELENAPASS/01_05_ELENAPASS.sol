// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ELENAPASS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    ELENAPASS    //
//                 //
//                 //
/////////////////////


contract ELENAPASS is ERC1155Creator {
    constructor() ERC1155Creator("ELENAPASS", "ELENAPASS") {}
}