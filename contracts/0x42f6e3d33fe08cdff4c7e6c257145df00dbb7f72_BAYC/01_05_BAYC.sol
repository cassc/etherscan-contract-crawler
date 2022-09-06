// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bored Ape Yacht CIub
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    Bored Ape Yacht Club by Yuga Labs    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract BAYC is ERC721Creator {
    constructor() ERC721Creator("Bored Ape Yacht CIub", "BAYC") {}
}