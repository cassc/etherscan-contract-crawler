// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Takopon Collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    (・◎・)    //
//             //
//             //
/////////////////


contract TAKOPON is ERC721Creator {
    constructor() ERC721Creator("Takopon Collection", "TAKOPON") {}
}