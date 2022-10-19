// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ProfilePicCollection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    PFP    //
//           //
//           //
///////////////


contract PFP is ERC721Creator {
    constructor() ERC721Creator("ProfilePicCollection", "PFP") {}
}