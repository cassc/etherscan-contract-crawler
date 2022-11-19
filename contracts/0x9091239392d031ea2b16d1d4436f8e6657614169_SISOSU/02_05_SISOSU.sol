// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SISO's Models
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    SISO...    //
//               //
//               //
///////////////////


contract SISOSU is ERC721Creator {
    constructor() ERC721Creator("SISO's Models", "SISOSU") {}
}