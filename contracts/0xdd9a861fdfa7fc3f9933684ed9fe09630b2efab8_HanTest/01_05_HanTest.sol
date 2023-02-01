// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HanTEST
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    Hi.    //
//           //
//           //
///////////////


contract HanTest is ERC721Creator {
    constructor() ERC721Creator("HanTEST", "HanTest") {}
}