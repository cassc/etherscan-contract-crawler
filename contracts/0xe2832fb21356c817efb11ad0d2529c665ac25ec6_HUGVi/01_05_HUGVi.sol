// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HUG Visionaries
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//                                   HUG Visionaries                                     //
//                                                                                       //
//    An initiative by HUG to provide financial support directly to emerging artists,    //
//    while amplifying their work and growing their personal collector network.          //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract HUGVi is ERC1155Creator {
    constructor() ERC1155Creator("HUG Visionaries", "HUGVi") {}
}