// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lisa x Commissions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    nftlisa    //
//               //
//               //
///////////////////


contract LFC is ERC721Creator {
    constructor() ERC721Creator("Lisa x Commissions", "LFC") {}
}