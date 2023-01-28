// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MemeCulture
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    try me.    //
//               //
//               //
///////////////////


contract CMM is ERC1155Creator {
    constructor() ERC1155Creator("MemeCulture", "CMM") {}
}