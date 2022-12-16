// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test Contract
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    N/A    //
//           //
//           //
///////////////


contract TEST129378 is ERC721Creator {
    constructor() ERC721Creator("Test Contract", "TEST129378") {}
}