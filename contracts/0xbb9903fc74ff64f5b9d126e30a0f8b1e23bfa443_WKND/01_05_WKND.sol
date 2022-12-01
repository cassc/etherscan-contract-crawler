// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: pre wknd
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    it was the wknd    //
//                       //
//                       //
///////////////////////////


contract WKND is ERC721Creator {
    constructor() ERC721Creator("pre wknd", "WKND") {}
}