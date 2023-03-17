// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A. L. Crego
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////
//         //
//         //
//    ·    //
//         //
//         //
/////////////


contract ALC is ERC721Creator {
    constructor() ERC721Creator("A. L. Crego", "ALC") {}
}