// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: John Wingfield Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    John Wingfield's NFTs    //
//                             //
//                             //
/////////////////////////////////


contract JWE is ERC1155Creator {
    constructor() ERC1155Creator("John Wingfield Editions", "JWE") {}
}