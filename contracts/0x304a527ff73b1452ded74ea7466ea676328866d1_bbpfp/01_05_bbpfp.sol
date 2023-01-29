// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bruce Bates PFPs
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    bbpfp    //
//             //
//             //
/////////////////


contract bbpfp is ERC721Creator {
    constructor() ERC721Creator("Bruce Bates PFPs", "bbpfp") {}
}