// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LOGU_NFT
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//     __    _____ _____ _____                             //
//    |  |  |     |   __|  |  |                            //
//    |  |__|  |  |  |  |  |  |                            //
//    |_____|_____|_____|_____|                            //
//                                                         //
//     _______ _______ _______                             //
//    |    |  |    ___|_     _|                            //
//    |       |    ___| |   |                              //
//    |__|____|___|     |___|                              //
//                                                         //
//                                                         //
//    photographer, crypto enthusiastic, always forward    //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract LOGU is ERC1155Creator {
    constructor() ERC1155Creator("LOGU_NFT", "LOGU") {}
}