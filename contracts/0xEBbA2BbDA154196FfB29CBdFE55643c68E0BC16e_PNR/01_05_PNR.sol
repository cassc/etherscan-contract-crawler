// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Life On The Line
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    PNR    //
//           //
//           //
///////////////


contract PNR is ERC721Creator {
    constructor() ERC721Creator("Life On The Line", "PNR") {}
}