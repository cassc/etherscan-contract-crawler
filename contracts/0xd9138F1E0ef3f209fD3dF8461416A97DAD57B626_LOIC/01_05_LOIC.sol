// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Loïc Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//                                                                          //
//     __         ______     __     ______     __  __     ______            //
//    /\ \       /\  __ \   /\ \   /\  ___\   /\ \/\ \   /\  ___\           //
//    \ \ \____  \ \ \/\ \  \ \ \  \ \ \____  \ \ \_\ \  \ \___  \          //
//     \ \_____\  \ \_____\  \ \_\  \ \_____\  \ \_____\  \/\_____\         //
//      \/_____/   \/_____/   \/_/   \/_____/   \/_____/   \/_____/         //
//                                                                          //
//    A contract to create worlds and tell the tales from their surface.    //
//                                                                          //
//    Multi-editions                                                        //
//                                                                          //
//    -Loïc R                                                               //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract LOIC is ERC1155Creator {
    constructor() ERC1155Creator(unicode"Loïc Editions", "LOIC") {}
}