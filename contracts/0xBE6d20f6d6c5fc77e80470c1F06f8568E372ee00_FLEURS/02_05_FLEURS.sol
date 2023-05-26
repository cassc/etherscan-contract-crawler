// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: À Propos des Fleurs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    À Propos des Fleurs    //
//                           //
//                           //
///////////////////////////////


contract FLEURS is ERC721Creator {
    constructor() ERC721Creator(unicode"À Propos des Fleurs", "FLEURS") {}
}