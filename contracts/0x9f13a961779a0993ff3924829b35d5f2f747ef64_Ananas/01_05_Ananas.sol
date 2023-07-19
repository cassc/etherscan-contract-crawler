// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Untold story with ananas
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    ???🍍🍍🍍🍍🍍🍍🍍🍍???     //
//                               //
//                               //
///////////////////////////////////


contract Ananas is ERC721Creator {
    constructor() ERC721Creator("Untold story with ananas", "Ananas") {}
}