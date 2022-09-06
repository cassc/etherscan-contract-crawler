// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alhucard 1/1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                 //
//                                                                                                 //
//    With love, I present the Alhucard 721 contract. This is my personal 1/1 NFT contract.        //
//    The intent of this contract is for minting my finest works, and to fulfill private sales.    //
//                                                                                                 //
//    I am Alhu, I am a creator and world builder.                                                 //
//    I aim to stimulate your imagination, and my own.                                             //
//    Thank you for your time, attention, and reverence.                                           //
//                                                                                                 //
//    Reckless ! 🥀                                                                                //
//                                                                                                 //
//    May my existence be in thanks,                                                               //
//    and may yours be guided by light.                                                            //
//                                                                                                 //
//                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////


contract ALHU is ERC721Creator {
    constructor() ERC721Creator("Alhucard 1/1", "ALHU") {}
}