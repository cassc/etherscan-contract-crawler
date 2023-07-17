// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BURNIMAL
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    0-0    //
//           //
//           //
///////////////


contract BURN is ERC1155Creator {
    constructor() ERC1155Creator("BURNIMAL", "BURN") {}
}