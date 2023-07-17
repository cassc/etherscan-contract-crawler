// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: special archive
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    dieLehmanns    //
//                   //
//                   //
///////////////////////


contract dLeh is ERC721Creator {
    constructor() ERC721Creator("special archive", "dLeh") {}
}