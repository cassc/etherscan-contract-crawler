// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Surreal Reality Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                               //
//                                                                                                                                               //
//    A self-taught artist, exploring the 2D/3D world and producing visual experiences with an emphasis on emotions and dystopian aesthetics.    //
//                                                                                                                                               //
//                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SRE is ERC1155Creator {
    constructor() ERC1155Creator("Surreal Reality Editions", "SRE") {}
}