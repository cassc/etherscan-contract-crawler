// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BETTERS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    BETTERS    //
//               //
//               //
///////////////////


contract BETTERS is ERC1155Creator {
    constructor() ERC1155Creator("BETTERS", "BETTERS") {}
}