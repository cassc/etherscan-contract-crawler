// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: lorem ipsum
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    108 105 112 115 117 109    //
//                               //
//                               //
///////////////////////////////////


contract LIPSUM is ERC721Creator {
    constructor() ERC721Creator("lorem ipsum", "LIPSUM") {}
}