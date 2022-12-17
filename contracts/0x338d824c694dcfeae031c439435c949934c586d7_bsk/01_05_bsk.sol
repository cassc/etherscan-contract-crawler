// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: anon1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    -ed    //
//           //
//           //
///////////////


contract bsk is ERC721Creator {
    constructor() ERC721Creator("anon1", "bsk") {}
}