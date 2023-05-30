// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CHILL PLACE PEPE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                _     _ _ _               //
//     _ __   ___ _ __   ___  ___| |__ (_) | | ___ _ __     //
//    | '_ \ / _ \ '_ \ / _ \/ __| '_ \| | | |/ _ \ '__|    //
//    | |_) |  __/ |_) |  __/ (__| | | | | | |  __/ |       //
//    | .__/ \___| .__/ \___|\___|_| |_|_|_|_|\___|_|       //
//    |_|        |_|                                        //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract CHLL is ERC1155Creator {
    constructor() ERC1155Creator("CHILL PLACE PEPE", "CHLL") {}
}