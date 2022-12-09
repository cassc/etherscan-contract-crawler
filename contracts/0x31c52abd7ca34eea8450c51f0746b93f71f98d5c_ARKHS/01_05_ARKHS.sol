// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ARKHAUS || Forever Memberships
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    ARKHAUS    //
//               //
//               //
///////////////////


contract ARKHS is ERC721Creator {
    constructor() ERC721Creator("ARKHAUS || Forever Memberships", "ARKHS") {}
}