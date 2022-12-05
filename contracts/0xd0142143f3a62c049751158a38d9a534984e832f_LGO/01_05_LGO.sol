// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Life Go On
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    LGO    //
//           //
//           //
///////////////


contract LGO is ERC1155Creator {
    constructor() ERC1155Creator("Life Go On", "LGO") {}
}