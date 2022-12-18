// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Juan of Juans
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    JOJ    //
//           //
//           //
///////////////


contract JOJ is ERC721Creator {
    constructor() ERC721Creator("Juan of Juans", "JOJ") {}
}