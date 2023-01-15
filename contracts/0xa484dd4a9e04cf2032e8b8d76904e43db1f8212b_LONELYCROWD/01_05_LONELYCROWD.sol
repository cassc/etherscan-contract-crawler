// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lonely Crowd
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    Lonely Crowd    //
//                    //
//                    //
////////////////////////


contract LONELYCROWD is ERC721Creator {
    constructor() ERC721Creator("Lonely Crowd", "LONELYCROWD") {}
}