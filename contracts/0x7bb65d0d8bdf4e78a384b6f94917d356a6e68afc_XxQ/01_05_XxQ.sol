// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: editions by XxQ
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    XxQ    //
//           //
//           //
///////////////


contract XxQ is ERC721Creator {
    constructor() ERC721Creator("editions by XxQ", "XxQ") {}
}