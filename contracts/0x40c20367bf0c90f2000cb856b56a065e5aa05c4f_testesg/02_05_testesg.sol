// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: testesg
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    test    //
//            //
//            //
////////////////


contract testesg is ERC721Creator {
    constructor() ERC721Creator("testesg", "testesg") {}
}