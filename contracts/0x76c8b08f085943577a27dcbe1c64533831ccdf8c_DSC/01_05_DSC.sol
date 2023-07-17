// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SMOLCARDS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    ______    //
//    |SMOL|    //
//    |~~~~|    //
//    |CARD|    //
//    ``````    //
//              //
//              //
//              //
//////////////////


contract DSC is ERC721Creator {
    constructor() ERC721Creator("SMOLCARDS", "DSC") {}
}