// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lost in translation
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//    Because in this space sometimes we all get lost in translation!    //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract HK is ERC1155Creator {
    constructor() ERC1155Creator("Lost in translation", "HK") {}
}