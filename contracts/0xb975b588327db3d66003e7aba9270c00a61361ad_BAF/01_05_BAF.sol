// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bryan Freudeman Art Manifold
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    BAF     //
//            //
//            //
////////////////


contract BAF is ERC721Creator {
    constructor() ERC721Creator("Bryan Freudeman Art Manifold", "BAF") {}
}