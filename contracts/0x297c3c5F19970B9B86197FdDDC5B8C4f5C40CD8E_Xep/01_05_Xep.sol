// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Xep
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    123    //
//           //
//           //
///////////////


contract Xep is ERC721Creator {
    constructor() ERC721Creator("Xep", "Xep") {}
}