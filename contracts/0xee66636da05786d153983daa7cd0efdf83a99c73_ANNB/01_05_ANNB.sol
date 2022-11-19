// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NeuralBricolage - Analogies
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    ASCII Art    //
//                 //
//                 //
/////////////////////


contract ANNB is ERC721Creator {
    constructor() ERC721Creator("NeuralBricolage - Analogies", "ANNB") {}
}