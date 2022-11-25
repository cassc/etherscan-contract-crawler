// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hash Demo X
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//    x    //
//         //
//         //
/////////////


contract HASH is ERC721Creator {
    constructor() ERC721Creator("Hash Demo X", "HASH") {}
}