// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ken Keiko
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    KenKeiko    //
//                //
//                //
////////////////////


contract KenKeiko is ERC1155Creator {
    constructor() ERC1155Creator("Ken Keiko", "KenKeiko") {}
}