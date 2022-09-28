// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CX
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    diud    //
//            //
//            //
////////////////


contract CloneX is ERC721Creator {
    constructor() ERC721Creator("CX", "CloneX") {}
}