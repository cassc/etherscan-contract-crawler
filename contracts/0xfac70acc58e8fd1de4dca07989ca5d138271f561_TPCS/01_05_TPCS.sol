// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tsuru's PFP Collection(Solo Exhibition Limited Edition)
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    (/・ω・)/    //
//               //
//               //
///////////////////


contract TPCS is ERC1155Creator {
    constructor() ERC1155Creator("Tsuru's PFP Collection(Solo Exhibition Limited Edition)", "TPCS") {}
}