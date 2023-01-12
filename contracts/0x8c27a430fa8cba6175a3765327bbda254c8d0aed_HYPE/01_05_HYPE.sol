// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hypothesis
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    xoxox    //
//             //
//             //
/////////////////


contract HYPE is ERC721Creator {
    constructor() ERC721Creator("Hypothesis", "HYPE") {}
}