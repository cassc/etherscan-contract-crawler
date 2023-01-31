// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Journey Begins
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    join us on this journey    //
//                               //
//                               //
///////////////////////////////////


contract JRNY is ERC1155Creator {
    constructor() ERC1155Creator("A Journey Begins", "JRNY") {}
}