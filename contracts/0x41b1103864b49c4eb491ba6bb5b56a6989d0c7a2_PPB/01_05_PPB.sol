// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PepeBet
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    pepebet    //
//               //
//               //
///////////////////


contract PPB is ERC721Creator {
    constructor() ERC721Creator("PepeBet", "PPB") {}
}