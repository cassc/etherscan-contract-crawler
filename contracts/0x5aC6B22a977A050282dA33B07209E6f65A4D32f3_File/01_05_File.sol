// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: File
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    Jah.    //
//            //
//            //
////////////////


contract File is ERC1155Creator {
    constructor() ERC1155Creator("File", "File") {}
}