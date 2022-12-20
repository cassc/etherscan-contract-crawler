// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Greeting card by iridori
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    ✉️    //
//          //
//          //
//////////////


contract GC is ERC1155Creator {
    constructor() ERC1155Creator("Greeting card by iridori", "GC") {}
}