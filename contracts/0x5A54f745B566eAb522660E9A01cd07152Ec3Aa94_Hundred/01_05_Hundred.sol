// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 100
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    100    //
//           //
//           //
///////////////


contract Hundred is ERC721Creator {
    constructor() ERC721Creator("100", "Hundred") {}
}