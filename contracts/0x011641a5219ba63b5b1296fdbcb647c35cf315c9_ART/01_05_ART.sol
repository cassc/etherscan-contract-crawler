// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ART by Désolé Maman
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    sorry, mom    //
//                  //
//                  //
//////////////////////


contract ART is ERC1155Creator {
    constructor() ERC1155Creator(unicode"ART by Désolé Maman", "ART") {}
}