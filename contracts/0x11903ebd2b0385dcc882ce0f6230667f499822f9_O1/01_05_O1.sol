// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Only ONE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////
//             //
//             //
//    Only1    //
//             //
//             //
/////////////////


contract O1 is ERC721Creator {
    constructor() ERC721Creator("Only ONE", "O1") {}
}