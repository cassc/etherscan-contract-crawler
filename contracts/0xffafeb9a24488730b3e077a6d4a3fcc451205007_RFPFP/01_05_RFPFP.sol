// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Robin Fischer PFPs
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    RF PFPs    //
//               //
//               //
///////////////////


contract RFPFP is ERC721Creator {
    constructor() ERC721Creator("Robin Fischer PFPs", "RFPFP") {}
}