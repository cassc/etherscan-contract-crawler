// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Taste of What’s to Come
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    ATWTC    //
//             //
//             //
/////////////////


contract ATWTC is ERC721Creator {
    constructor() ERC721Creator(unicode"A Taste of What’s to Come", "ATWTC") {}
}