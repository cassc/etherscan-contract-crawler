// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BRAIN DRAWINGS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    GET YOUR DOODLES HERE    //
//                             //
//                             //
/////////////////////////////////


contract BD is ERC721Creator {
    constructor() ERC721Creator("BRAIN DRAWINGS", "BD") {}
}