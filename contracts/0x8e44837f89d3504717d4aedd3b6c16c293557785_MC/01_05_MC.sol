// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Modern Classicism
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    /\/\[    //
//             //
//             //
/////////////////


contract MC is ERC721Creator {
    constructor() ERC721Creator("Modern Classicism", "MC") {}
}