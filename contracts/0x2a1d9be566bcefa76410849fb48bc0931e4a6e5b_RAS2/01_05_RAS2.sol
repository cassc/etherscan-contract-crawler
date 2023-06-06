// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Redeemed Asset 2
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    RAAS2    //
//             //
//             //
/////////////////


contract RAS2 is ERC721Creator {
    constructor() ERC721Creator("Redeemed Asset 2", "RAS2") {}
}