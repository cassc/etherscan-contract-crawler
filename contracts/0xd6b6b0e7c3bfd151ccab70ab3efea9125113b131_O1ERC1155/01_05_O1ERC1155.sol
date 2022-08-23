// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OnlyOnw1155
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    O1ERC1155    //
//                 //
//                 //
/////////////////////


contract O1ERC1155 is ERC1155Creator {
    constructor() ERC1155Creator() {}
}