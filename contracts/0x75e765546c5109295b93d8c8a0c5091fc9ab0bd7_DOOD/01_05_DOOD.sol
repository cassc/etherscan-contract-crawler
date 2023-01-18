// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Actives
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    DOODLES    //
//               //
//               //
///////////////////


contract DOOD is ERC721Creator {
    constructor() ERC721Creator("The Actives", "DOOD") {}
}