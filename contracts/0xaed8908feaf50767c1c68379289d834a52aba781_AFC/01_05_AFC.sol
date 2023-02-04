// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Al & Frank's Colors
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    AFC    //
//           //
//           //
///////////////


contract AFC is ERC721Creator {
    constructor() ERC721Creator("Al & Frank's Colors", "AFC") {}
}