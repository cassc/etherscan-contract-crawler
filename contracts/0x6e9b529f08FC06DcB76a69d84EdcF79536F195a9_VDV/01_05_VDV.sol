// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: voce del verbo
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    vdv    //
//           //
//           //
///////////////


contract VDV is ERC721Creator {
    constructor() ERC721Creator("voce del verbo", "VDV") {}
}