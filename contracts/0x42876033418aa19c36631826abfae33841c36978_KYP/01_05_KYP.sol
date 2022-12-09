// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KYP005
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    ✤✤✤    //
//           //
//           //
///////////////


contract KYP is ERC721Creator {
    constructor() ERC721Creator("KYP005", "KYP") {}
}