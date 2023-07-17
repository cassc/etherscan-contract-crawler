// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MM NFT Test
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    This is a test contract    //
//                               //
//                               //
///////////////////////////////////


contract MMNT is ERC1155Creator {
    constructor() ERC1155Creator("MM NFT Test", "MMNT") {}
}