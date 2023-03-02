// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sebeth ERC1155
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    Sebeth    //
//              //
//              //
//////////////////


contract Sebeth is ERC1155Creator {
    constructor() ERC1155Creator("Sebeth ERC1155", "Sebeth") {}
}