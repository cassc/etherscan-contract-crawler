// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eternal Apes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//     ____ ____ ____   ___   __   ____     //
//    (  _ ( ___|  _ \ / __) /__\ (  _ \    //
//     )   /)__) )(_) | (__ /(__)\ )___/    //
//    (_)\_|____|____/ \___|__)(__|__)      //
//                                          //
//                                          //
//////////////////////////////////////////////


contract ETAPE is ERC721Creator {
    constructor() ERC721Creator("Eternal Apes", "ETAPE") {}
}