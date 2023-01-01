// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: weltraum
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    WELTRAUM CONTRACT 1.0    //
//                             //
//                             //
/////////////////////////////////


contract WELTRAM is ERC721Creator {
    constructor() ERC721Creator("weltraum", "WELTRAM") {}
}