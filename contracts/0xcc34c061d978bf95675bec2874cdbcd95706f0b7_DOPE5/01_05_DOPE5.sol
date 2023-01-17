// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: dope5how
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//    The original dope5how collection. New pieces added (almost) daily.     //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract DOPE5 is ERC1155Creator {
    constructor() ERC1155Creator("dope5how", "DOPE5") {}
}