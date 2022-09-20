// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bleu Merge
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    bleumerge    //
//                 //
//                 //
/////////////////////


contract BLEUMERGE is ERC721Creator {
    constructor() ERC721Creator("Bleu Merge", "BLEUMERGE") {}
}