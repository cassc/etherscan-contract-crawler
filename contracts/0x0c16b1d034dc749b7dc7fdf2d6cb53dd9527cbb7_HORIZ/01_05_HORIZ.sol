// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Horizon
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    DOANK    //
//             //
//             //
/////////////////


contract HORIZ is ERC721Creator {
    constructor() ERC721Creator("Horizon", "HORIZ") {}
}