// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eoj
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    gm wrld    //
//               //
//               //
///////////////////


contract eoj is ERC721Creator {
    constructor() ERC721Creator("Eoj", "eoj") {}
}