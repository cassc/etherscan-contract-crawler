// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Herein Lies Magic
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    ✨    //
//         //
//         //
/////////////


contract HLM is ERC721Creator {
    constructor() ERC721Creator("Herein Lies Magic", "HLM") {}
}