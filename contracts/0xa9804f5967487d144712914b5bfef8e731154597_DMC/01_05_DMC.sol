// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: D-muscle
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                     //
//                                                                                                     //
//    This token are yours if you want to have. But if you don’t like to work out you can't get it.    //
//                                                                                                     //
//                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DMC is ERC721Creator {
    constructor() ERC721Creator("D-muscle", "DMC") {}
}