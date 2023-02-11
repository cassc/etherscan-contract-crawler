// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Web3 2023 Awards The Big Whale
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    r    //
//         //
//         //
/////////////


contract TBW23 is ERC721Creator {
    constructor() ERC721Creator("Web3 2023 Awards The Big Whale", "TBW23") {}
}