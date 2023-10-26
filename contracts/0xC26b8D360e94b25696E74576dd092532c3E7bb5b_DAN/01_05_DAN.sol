// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dan_SRL
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    .!.-_-.!.    //
//                 //
//                 //
/////////////////////


contract DAN is ERC721Creator {
    constructor() ERC721Creator("Dan_SRL", "DAN") {}
}