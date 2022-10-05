// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GFY Is Best Dressed
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//    if somebody says you can't, you say GOFUNKEYOURSELF.    //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract GFY is ERC721Creator {
    constructor() ERC721Creator("GFY Is Best Dressed", "GFY") {}
}