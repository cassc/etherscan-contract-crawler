// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crystals of the Light V2
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//    CrystalsoftheLight.Blockchain                            //
//    CrystalsoftheLight.Tez                                   //
//    CrystalsoftheLight.Eth                                   //
//                                                             //
//    NFT Digital Assets                                       //
//    GOD TOKEN Contract Address:                              //
//    Polygon & Ethereum                                       //
//    0xf655544B1863a3c3E360E834f2741Cb4BF50D5Ae               //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract GOD is ERC1155Creator {
    constructor() ERC1155Creator("Crystals of the Light V2", "GOD") {}
}