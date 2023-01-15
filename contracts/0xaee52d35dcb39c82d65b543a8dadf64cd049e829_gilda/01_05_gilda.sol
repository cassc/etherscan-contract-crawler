// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: gilda atefat
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    GILDA    //
//             //
//             //
/////////////////


contract gilda is ERC721Creator {
    constructor() ERC721Creator("gilda atefat", "gilda") {}
}