// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JKTLM Vector
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    -------->    //
//                 //
//                 //
/////////////////////


contract VCTR is ERC721Creator {
    constructor() ERC721Creator("JKTLM Vector", "VCTR") {}
}