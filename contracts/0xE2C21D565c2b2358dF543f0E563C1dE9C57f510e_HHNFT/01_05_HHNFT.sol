// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HIP HOP & PHOTOGRAPHY & NFTS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//    HIP HOP & PHOTOGRAPHY & NFTS                     //
//    This collection brings together photographers    //
//    of different generations and locations           //
//    registering on the blockchain                    //
//    part of Hip Hop history,                         //
//    in its most comprehensive forms,                 //
//    from the USA to Brazil,                          //
//    from the OGs to the new stars.                   //
//                                                     //
//    http://nftrio.io                                 //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract HHNFT is ERC721Creator {
    constructor() ERC721Creator("HIP HOP & PHOTOGRAPHY & NFTS", "HHNFT") {}
}