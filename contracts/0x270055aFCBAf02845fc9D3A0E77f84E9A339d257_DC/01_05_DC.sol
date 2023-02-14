// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Doge Checks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    Doge Checks    //
//                   //
//                   //
///////////////////////


contract DC is ERC1155Creator {
    constructor() ERC1155Creator("Doge Checks", "DC") {}
}