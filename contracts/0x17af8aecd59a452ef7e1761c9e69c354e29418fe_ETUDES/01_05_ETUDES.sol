// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ÉTUDES
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    ÉTUDES    //
//              //
//              //
//////////////////


contract ETUDES is ERC721Creator {
    constructor() ERC721Creator(unicode"ÉTUDES", "ETUDES") {}
}