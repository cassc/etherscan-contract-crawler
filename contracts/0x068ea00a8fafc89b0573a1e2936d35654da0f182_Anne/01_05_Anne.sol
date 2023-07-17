// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anne Canvas
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    Anne Canvas    //
//    Anne           //
//                   //
//                   //
///////////////////////


contract Anne is ERC1155Creator {
    constructor() ERC1155Creator("Anne Canvas", "Anne") {}
}