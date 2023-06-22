// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Festisia Boarding Pass
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//       MAKE LIFE A FESTIVAL    //
//                               //
//                               //
///////////////////////////////////


contract FBP is ERC721Creator {
    constructor() ERC721Creator("Festisia Boarding Pass", "FBP") {}
}