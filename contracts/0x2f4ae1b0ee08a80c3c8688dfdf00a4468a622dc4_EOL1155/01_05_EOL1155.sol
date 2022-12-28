// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EOL ERC1155
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    EOL1155    //
//               //
//               //
///////////////////


contract EOL1155 is ERC1155Creator {
    constructor() ERC1155Creator("EOL ERC1155", "EOL1155") {}
}