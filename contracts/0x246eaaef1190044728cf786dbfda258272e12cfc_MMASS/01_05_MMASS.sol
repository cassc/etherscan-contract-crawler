// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Metamask, I Ask
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    YOU GOT THIS    //
//                    //
//                    //
////////////////////////


contract MMASS is ERC721Creator {
    constructor() ERC721Creator("Metamask, I Ask", "MMASS") {}
}