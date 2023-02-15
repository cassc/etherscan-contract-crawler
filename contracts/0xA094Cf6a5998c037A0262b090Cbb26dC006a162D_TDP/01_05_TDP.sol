// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Divergents: Philanthropist
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    -    //
//         //
//         //
/////////////


contract TDP is ERC721Creator {
    constructor() ERC721Creator("The Divergents: Philanthropist", "TDP") {}
}