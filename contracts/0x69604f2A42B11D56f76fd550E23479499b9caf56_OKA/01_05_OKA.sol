// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: omakase_additions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    _ [ ] _    //
//               //
//               //
///////////////////


contract OKA is ERC1155Creator {
    constructor() ERC1155Creator("omakase_additions", "OKA") {}
}