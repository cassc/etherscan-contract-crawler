// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MAYURI
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    ///    //
//           //
//           //
///////////////


contract MAYURI is ERC721Creator {
    constructor() ERC721Creator("MAYURI", "MAYURI") {}
}