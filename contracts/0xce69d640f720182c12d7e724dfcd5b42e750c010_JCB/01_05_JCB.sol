// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Backman’s Creations
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    |~) _  _| ._ _  _ ._     //
//    |_)(_|(_|<| | |(_|| |    //
//                             //
//                             //
/////////////////////////////////


contract JCB is ERC721Creator {
    constructor() ERC721Creator(unicode"Backman’s Creations", "JCB") {}
}