// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Soldiers of the Metaverse Diamond Pass
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    Soldiers of the Metaverse     //
//                                  //
//         Diamond Pass             //
//                                  //
//                                  //
//////////////////////////////////////


contract DPASS is ERC721Creator {
    constructor() ERC721Creator("Soldiers of the Metaverse Diamond Pass", "DPASS") {}
}