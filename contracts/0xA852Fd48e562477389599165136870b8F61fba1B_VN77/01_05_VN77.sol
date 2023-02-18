// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: virginNFT77
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    virginNFT77    //
//                   //
//                   //
///////////////////////


contract VN77 is ERC1155Creator {
    constructor() ERC1155Creator("virginNFT77", "VN77") {}
}