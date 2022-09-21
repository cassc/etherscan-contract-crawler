// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OVW Archive
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//    To the eternal disruptors, the romantics, and the visionaries.    //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract ovw is ERC721Creator {
    constructor() ERC721Creator("OVW Archive", "ovw") {}
}