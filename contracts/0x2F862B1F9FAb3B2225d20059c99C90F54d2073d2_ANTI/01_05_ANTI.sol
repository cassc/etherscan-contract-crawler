// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: jawbreaker0x
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    ascii and you shall receivii!    //
//                                     //
//                                     //
/////////////////////////////////////////


contract ANTI is ERC721Creator {
    constructor() ERC721Creator("jawbreaker0x", "ANTI") {}
}