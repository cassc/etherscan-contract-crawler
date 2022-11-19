// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FaKe Noble CaRds
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    What is real     //
//                     //
//                     //
/////////////////////////


contract FNC is ERC721Creator {
    constructor() ERC721Creator("FaKe Noble CaRds", "FNC") {}
}