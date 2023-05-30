// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Krista Awad
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    Visual Artist. Based in La.      //
//                                     //
//                                     //
/////////////////////////////////////////


contract KA is ERC721Creator {
    constructor() ERC721Creator("Krista Awad", "KA") {}
}