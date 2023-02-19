// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Skull Islands
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    Skull    //
//             //
//             //
/////////////////


contract Skull is ERC721Creator {
    constructor() ERC721Creator("Skull Islands", "Skull") {}
}