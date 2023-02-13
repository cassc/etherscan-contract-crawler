// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dazai
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    Dazai    //
//             //
//             //
/////////////////


contract DZ is ERC721Creator {
    constructor() ERC721Creator("Dazai", "DZ") {}
}