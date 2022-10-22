// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BLaNc
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////
//         //
//         //
//    □    //
//         //
//         //
//         //
//         //
/////////////


contract BLANK is ERC721Creator {
    constructor() ERC721Creator("BLaNc", "BLANK") {}
}