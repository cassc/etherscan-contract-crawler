// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BNB
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    BNB    //
//           //
//           //
///////////////


contract BNB is ERC721Creator {
    constructor() ERC721Creator("BNB", "BNB") {}
}