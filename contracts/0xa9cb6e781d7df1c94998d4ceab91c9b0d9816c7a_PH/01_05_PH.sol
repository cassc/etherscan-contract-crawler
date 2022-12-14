// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Phake
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    Phake    //
//             //
//             //
/////////////////


contract PH is ERC721Creator {
    constructor() ERC721Creator("Phake", "PH") {}
}