// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Trident
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    created by sibileva.eth    //
//                               //
//                               //
///////////////////////////////////


contract TRDNT is ERC721Creator {
    constructor() ERC721Creator("The Trident", "TRDNT") {}
}