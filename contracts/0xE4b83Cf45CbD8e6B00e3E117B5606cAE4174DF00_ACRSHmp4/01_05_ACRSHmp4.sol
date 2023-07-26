// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anti-crash_mp4
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    ARSHMP4    //
//               //
//               //
///////////////////


contract ACRSHmp4 is ERC721Creator {
    constructor() ERC721Creator("Anti-crash_mp4", "ACRSHmp4") {}
}