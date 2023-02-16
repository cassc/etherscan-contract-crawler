// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Proof of Work
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                            //
//    A collection of 19 Open edition artist-made NFTs from an art experiment project                                                                                                                                                         //
//    by salmanfineart that uses proof-of-work blockchain theory to capture and                                                                                                                                                               //
//    document the creative process and its movement at every step of creation.                                                                                                                                                               //
//                                                                                                                                                                                                                                            //
//    A chance to allow collectors to be involved in each of step of the art-making                                                                                                                                                           //
//    process, and have the opportunity to own the artwork at different instances                                                                                                                                                             //
//    of creation of their preference.                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                            //
//    Utilities:                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                            //
//    1. One art print giveaway for each of 19 NFT to be won via raffle.                                                                                                                                                                      //
//    2. Five embellished art prints hand signed & personalised to the                                                                                                                                                                        //
//    NFT collectors name, ens or wallet address.                                                                                                                                                                                             //
//    3. Holders can purchase art prints & merch of their NFTs at a                                                                                                                                                                           //
//    later stage on the website store.                                                                                                                                                                                                       //
//    4. Allow List for future project drops.                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                            //
//    Read more about it on the website: www.salmanfineart.com/nft/pow                                                                                                                                                                        //
//                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PoW is ERC1155Creator {
    constructor() ERC1155Creator("Proof of Work", "PoW") {}
}