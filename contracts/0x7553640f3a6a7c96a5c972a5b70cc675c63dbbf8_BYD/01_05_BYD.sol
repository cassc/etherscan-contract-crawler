// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Beyond
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    DOANK    //
//             //
//             //
/////////////////


contract BYD is ERC721Creator {
    constructor() ERC721Creator("Beyond", "BYD") {}
}