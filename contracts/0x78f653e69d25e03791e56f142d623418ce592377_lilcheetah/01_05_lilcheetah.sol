// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lil Cheetah
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//    .    //
//         //
//         //
/////////////


contract lilcheetah is ERC721Creator {
    constructor() ERC721Creator("Lil Cheetah", "lilcheetah") {}
}