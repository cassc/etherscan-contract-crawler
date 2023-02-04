// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Privilege NFT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//         //
//         //
//         //
/////////////


contract TSH is ERC721Creator {
    constructor() ERC721Creator("Privilege NFT", "TSH") {}
}