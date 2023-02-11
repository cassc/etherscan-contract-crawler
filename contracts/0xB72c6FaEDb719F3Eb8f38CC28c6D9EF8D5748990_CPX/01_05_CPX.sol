// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Complexity
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    CPx    //
//           //
//           //
///////////////


contract CPX is ERC721Creator {
    constructor() ERC721Creator("Complexity", "CPX") {}
}