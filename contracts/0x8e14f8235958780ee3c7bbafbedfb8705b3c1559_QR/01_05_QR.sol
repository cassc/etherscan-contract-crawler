// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Q!R
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    Q!R    //
//           //
//           //
///////////////


contract QR is ERC721Creator {
    constructor() ERC721Creator("Q!R", "QR") {}
}