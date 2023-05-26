// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nyan Pepe
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    NYAN PEPE    //
//                 //
//                 //
/////////////////////


contract NYANPEPE is ERC1155Creator {
    constructor() ERC1155Creator("Nyan Pepe", "NYANPEPE") {}
}