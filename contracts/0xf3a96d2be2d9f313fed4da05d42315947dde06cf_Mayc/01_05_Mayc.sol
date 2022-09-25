// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mutant Ape Yacht Clubb
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    XNXX    //
//            //
//            //
////////////////


contract Mayc is ERC721Creator {
    constructor() ERC721Creator("Mutant Ape Yacht Clubb", "Mayc") {}
}