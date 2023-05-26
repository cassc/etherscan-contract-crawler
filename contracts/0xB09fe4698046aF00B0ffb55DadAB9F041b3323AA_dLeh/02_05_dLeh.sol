// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dops in the Air
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
    constructor() ERC721Creator("Dops in the Air", "dLeh") {}
}