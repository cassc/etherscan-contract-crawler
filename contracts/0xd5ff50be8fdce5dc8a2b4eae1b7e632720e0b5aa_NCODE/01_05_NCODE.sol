// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NO_CODE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    no-code    //
//               //
//               //
///////////////////


contract NCODE is ERC721Creator {
    constructor() ERC721Creator("NO_CODE", "NCODE") {}
}