// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SamJ Studios
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    .    //
//         //
//         //
/////////////


contract SamJ is ERC721Creator {
    constructor() ERC721Creator("SamJ Studios", "SamJ") {}
}