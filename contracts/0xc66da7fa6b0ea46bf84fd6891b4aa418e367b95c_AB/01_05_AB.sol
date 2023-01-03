// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Atul Boylla
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    Atul Boylla    //
//                   //
//                   //
///////////////////////


contract AB is ERC1155Creator {
    constructor() ERC1155Creator("Atul Boylla", "AB") {}
}