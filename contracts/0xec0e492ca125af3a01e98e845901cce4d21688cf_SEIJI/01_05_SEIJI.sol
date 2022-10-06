// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SEIJI Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    SEIJI    //
//             //
//             //
/////////////////


contract SEIJI is ERC721Creator {
    constructor() ERC721Creator("SEIJI Collection", "SEIJI") {}
}