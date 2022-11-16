// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Proof of Bear
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    POB    //
//           //
//           //
///////////////


contract POB is ERC721Creator {
    constructor() ERC721Creator("Proof of Bear", "POB") {}
}