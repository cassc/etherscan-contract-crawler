// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MEELO EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//        _______ _______ _______         _____       _______ ______         //
//        |  |  | |______ |______ |      |     |      |______ |     \        //
//        |  |  | |______ |______ |_____ |_____|      |______ |_____/        //
//                                                                           //
//     ARTWORK FOR THE HOMIES, CHAMPIONS, LEGENDS, DONS & ALL THE ABOVE.     //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract MEELO is ERC1155Creator {
    constructor() ERC1155Creator("MEELO EDITIONS", "MEELO") {}
}