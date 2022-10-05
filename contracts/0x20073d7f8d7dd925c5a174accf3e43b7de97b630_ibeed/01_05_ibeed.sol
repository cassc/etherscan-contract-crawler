// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: iBEED Brand
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                             //
//                                                                                             //
//    iBEED - Trademark registered at INPI Brazil under protocol 919668160 since 12/29/2020    //
//                                                                                             //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////


contract ibeed is ERC721Creator {
    constructor() ERC721Creator("iBEED Brand", "ibeed") {}
}