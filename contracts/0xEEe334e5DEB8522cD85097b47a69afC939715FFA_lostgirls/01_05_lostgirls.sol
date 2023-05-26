// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vintage Girls
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////
//               //
//               //
//    nftlisa    //
//               //
//               //
///////////////////


contract lostgirls is ERC721Creator {
    constructor() ERC721Creator("Vintage Girls", "lostgirls") {}
}