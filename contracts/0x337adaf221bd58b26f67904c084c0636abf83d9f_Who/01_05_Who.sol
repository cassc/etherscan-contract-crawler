// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Who
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    Who    //
//           //
//           //
///////////////


contract Who is ERC721Creator {
    constructor() ERC721Creator("Who", "Who") {}
}