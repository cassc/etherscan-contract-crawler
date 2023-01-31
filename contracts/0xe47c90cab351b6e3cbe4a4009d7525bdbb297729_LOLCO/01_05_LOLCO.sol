// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LOL™ | & Co
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    LOL™ & Co | Artist Collaboration Open Editions    //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract LOLCO is ERC1155Creator {
    constructor() ERC1155Creator(unicode"LOL™ | & Co", "LOLCO") {}
}