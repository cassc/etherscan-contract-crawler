// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Golden Phi (Reborn)
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//                                                               //
//    #    ____              _     _   _   _ _ _                 //
//    #   |  _ \  __ ___   _(_) __| | | | | | | | ___   __ _     //
//    #   | | | |/ _` \ \ / / |/ _` | | | | | | |/ _ \ / _` |    //
//    #   | |_| | (_| |\ V /| | (_| | | |_| | | | (_) | (_| |    //
//    #   |____/ \__,_| \_/ |_|\__,_|  \___/|_|_|\___/ \__,_|    //
//    #                                                          //
//                                                               //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract GPhi is ERC721Creator {
    constructor() ERC721Creator("Golden Phi (Reborn)", "GPhi") {}
}