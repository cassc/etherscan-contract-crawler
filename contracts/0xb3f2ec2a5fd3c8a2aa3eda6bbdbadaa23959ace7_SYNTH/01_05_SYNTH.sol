// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Synthwave Vibes
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Synthwave Vibes    //
//                       //
//                       //
///////////////////////////


contract SYNTH is ERC721Creator {
    constructor() ERC721Creator("Synthwave Vibes", "SYNTH") {}
}