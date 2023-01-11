// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MorSella's Art particles & noise
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    MSA    //
//           //
//           //
///////////////


contract MSA is ERC721Creator {
    constructor() ERC721Creator("MorSella's Art particles & noise", "MSA") {}
}