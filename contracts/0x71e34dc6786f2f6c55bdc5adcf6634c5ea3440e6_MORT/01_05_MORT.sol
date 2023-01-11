// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MORTGAGE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//     _          _                          //
//    | |        | |                         //
//    | |__   ___| |_ __  _ __ ___   ___     //
//    | '_ \ / _ \ | '_ \| '_ ` _ \ / _ \    //
//    | | | |  __/ | |_) | | | | | |  __/    //
//    |_| |_|\___|_| .__/|_| |_| |_|\___|    //
//                 | |                       //
//                 |_|                       //
//                                           //
//                                           //
///////////////////////////////////////////////


contract MORT is ERC721Creator {
    constructor() ERC721Creator("MORTGAGE", "MORT") {}
}