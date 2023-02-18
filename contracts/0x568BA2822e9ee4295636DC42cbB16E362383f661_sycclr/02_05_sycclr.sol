// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: sycclr'
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    ~ sycclr' ~    //
//                   //
//                   //
///////////////////////


contract sycclr is ERC721Creator {
    constructor() ERC721Creator("sycclr'", "sycclr") {}
}