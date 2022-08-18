// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Generative Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    CGL    //
//           //
//           //
///////////////


contract AIA is ERC721Creator {
    constructor() ERC721Creator("Generative Art", "AIA") {}
}