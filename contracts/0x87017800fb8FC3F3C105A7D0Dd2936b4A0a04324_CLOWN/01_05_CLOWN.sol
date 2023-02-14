// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Clowns
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    CLOWN    //
//             //
//             //
/////////////////


contract CLOWN is ERC721Creator {
    constructor() ERC721Creator("Clowns", "CLOWN") {}
}