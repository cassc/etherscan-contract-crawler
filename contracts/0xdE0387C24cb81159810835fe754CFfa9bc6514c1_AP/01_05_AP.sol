// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ART POLICE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//        \     _ \__ __|   _ \   _ \  |    _ _|  ___| ____|     //
//       _ \   |   |  |    |   | |   | |      |  |     __|       //
//      ___ \  __ <   |    ___/  |   | |      |  |     |         //
//    _/    _\_| \_\ _|   _|    \___/ _____|___|\____|_____|     //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract AP is ERC1155Creator {
    constructor() ERC1155Creator("ART POLICE", "AP") {}
}