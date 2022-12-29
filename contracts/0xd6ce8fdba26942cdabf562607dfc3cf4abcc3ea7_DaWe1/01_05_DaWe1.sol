// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DaWe1/1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    DaWe1    //
//             //
//             //
/////////////////


contract DaWe1 is ERC721Creator {
    constructor() ERC721Creator("DaWe1/1", "DaWe1") {}
}