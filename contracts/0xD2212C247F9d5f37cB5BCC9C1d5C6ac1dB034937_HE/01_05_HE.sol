// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 半影
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    HAN-EI    //
//              //
//              //
//////////////////


contract HE is ERC721Creator {
    constructor() ERC721Creator(unicode"半影", "HE") {}
}