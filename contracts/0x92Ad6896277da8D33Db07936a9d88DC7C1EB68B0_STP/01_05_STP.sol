// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stand to Pee
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    STP    //
//           //
//           //
///////////////


contract STP is ERC1155Creator {
    constructor() ERC1155Creator("Stand to Pee", "STP") {}
}