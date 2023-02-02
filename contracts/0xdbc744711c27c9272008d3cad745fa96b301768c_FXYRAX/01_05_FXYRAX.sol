// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FXYRAX EDİTİONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    fxyrax    //
//              //
//              //
//////////////////


contract FXYRAX is ERC1155Creator {
    constructor() ERC1155Creator(unicode"FXYRAX EDİTİONS", "FXYRAX") {}
}