// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PAI Thoughts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    Thoughts    //
//                //
//                //
////////////////////


contract PAIT is ERC721Creator {
    constructor() ERC721Creator("PAI Thoughts", "PAIT") {}
}