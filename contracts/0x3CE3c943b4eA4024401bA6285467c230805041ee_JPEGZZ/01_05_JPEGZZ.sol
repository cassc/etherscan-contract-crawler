// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Save Your JPEGZZ V2
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    JPEGZZ    //
//              //
//              //
//////////////////


contract JPEGZZ is ERC1155Creator {
    constructor() ERC1155Creator("Save Your JPEGZZ V2", "JPEGZZ") {}
}