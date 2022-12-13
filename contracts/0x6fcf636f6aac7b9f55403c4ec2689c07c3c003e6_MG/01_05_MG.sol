// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mushroom Galaxy
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    Viktor    //
//              //
//              //
//////////////////


contract MG is ERC1155Creator {
    constructor() ERC1155Creator("Mushroom Galaxy", "MG") {}
}