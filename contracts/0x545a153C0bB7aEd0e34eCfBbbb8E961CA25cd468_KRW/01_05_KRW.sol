// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KKZ Requests works
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////
//            //
//            //
//    KKZ     //
//            //
//            //
////////////////


contract KRW is ERC721Creator {
    constructor() ERC721Creator("KKZ Requests works", "KRW") {}
}