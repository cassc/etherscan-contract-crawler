// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Irene's Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//    This is the beginning of my artistic journey.    //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract IRENE is ERC721Creator {
    constructor() ERC721Creator("Irene's Art", "IRENE") {}
}