// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mad dog
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    yes    //
//           //
//           //
///////////////


contract ESG is ERC721Creator {
    constructor() ERC721Creator("mad dog", "ESG") {}
}