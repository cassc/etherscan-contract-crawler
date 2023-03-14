// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Begetrare
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    101    //
//           //
//           //
///////////////


contract SPIRAL is ERC721Creator {
    constructor() ERC721Creator("Begetrare", "SPIRAL") {}
}