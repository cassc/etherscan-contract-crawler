// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UnChecks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    BroqLee    //
//               //
//               //
///////////////////


contract UNCHK is ERC721Creator {
    constructor() ERC721Creator("UnChecks", "UNCHK") {}
}