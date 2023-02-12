// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: nuit7
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    nuit7    //
//             //
//             //
/////////////////


contract nuit7 is ERC721Creator {
    constructor() ERC721Creator("nuit7", "nuit7") {}
}