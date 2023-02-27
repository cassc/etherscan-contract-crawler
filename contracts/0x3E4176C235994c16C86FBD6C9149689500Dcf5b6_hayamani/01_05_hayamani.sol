// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HANI HAYA Manifold contract
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    owohaya    //
//               //
//               //
///////////////////


contract hayamani is ERC721Creator {
    constructor() ERC721Creator("HANI HAYA Manifold contract", "hayamani") {}
}