// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Minimalism Fellings
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    .    //
//         //
//         //
/////////////


contract MMF is ERC721Creator {
    constructor() ERC721Creator("Minimalism Fellings", "MMF") {}
}