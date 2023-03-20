// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rolen Christoper
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    RCP    //
//           //
//           //
///////////////


contract RCP is ERC721Creator {
    constructor() ERC721Creator("Rolen Christoper", "RCP") {}
}