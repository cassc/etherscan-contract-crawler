// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: image me
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//    A collection of 1111 unique hand drawn nfts , imagination is needed    //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract IM is ERC721Creator {
    constructor() ERC721Creator("image me", "IM") {}
}