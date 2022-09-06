// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Fuckles Animated Shorts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//    ♾    //
//         //
//         //
/////////////


contract TFAS is ERC721Creator {
    constructor() ERC721Creator("The Fuckles Animated Shorts", "TFAS") {}
}