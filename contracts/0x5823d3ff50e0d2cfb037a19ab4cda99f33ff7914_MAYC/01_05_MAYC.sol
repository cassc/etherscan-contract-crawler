// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mutant Ape Yacht CIubs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//    .    //
//         //
//         //
/////////////


contract MAYC is ERC721Creator {
    constructor() ERC721Creator("Mutant Ape Yacht CIubs", "MAYC") {}
}