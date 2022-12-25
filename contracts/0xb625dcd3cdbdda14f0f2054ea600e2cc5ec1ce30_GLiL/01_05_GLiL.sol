// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GLiL
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    - GLiL -    //
//                //
//                //
////////////////////


contract GLiL is ERC721Creator {
    constructor() ERC721Creator("GLiL", "GLiL") {}
}