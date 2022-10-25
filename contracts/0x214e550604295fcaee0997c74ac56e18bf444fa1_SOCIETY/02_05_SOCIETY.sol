// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Society
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    >:/    //
//           //
//           //
///////////////


contract SOCIETY is ERC721Creator {
    constructor() ERC721Creator("The Society", "SOCIETY") {}
}