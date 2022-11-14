// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DEV
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    DEV    //
//           //
//           //
///////////////


contract DEV is ERC721Creator {
    constructor() ERC721Creator("DEV", "DEV") {}
}