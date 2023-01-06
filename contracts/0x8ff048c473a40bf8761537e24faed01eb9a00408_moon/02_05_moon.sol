// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: fullmoon collection 2023
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    (*'x'*)    //
//               //
//               //
///////////////////


contract moon is ERC721Creator {
    constructor() ERC721Creator("fullmoon collection 2023", "moon") {}
}