// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Casting Couch Pepe
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    Pepe gon pepe    //
//                     //
//                     //
/////////////////////////


contract SLOOT is ERC1155Creator {
    constructor() ERC1155Creator("Casting Couch Pepe", "SLOOT") {}
}