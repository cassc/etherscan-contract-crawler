// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Maiskaya
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//    m isk y                                                                            //
//     X   X X                                                                           //
//     X   X X                                                                           //
//     .   . .                                                                           //
//     .   . .                                                                           //
//     .   . .                                                                           //
//     .   . .                                                                           //
//                                                                                       //
//    maiskaya                                                                           //
//                                                                                       //
//    Creator Anastasiia Maiskaya                                                        //
//    https://twitter.com/maiskaya__a                                                    //
//                                                                                       //
//    License: NFT holder is free to use in advertising,                                 //
//    display privately and in groups, including galleries,                              //
//    documentaries and essays by holder of the NFT, as long as creator is credited.     //
//    Provides no rights to create commercial merchandise,                               //
//    commercial distribution or derivative works.                                       //
//    Copyright remains with the creator.                                                //
//                                                                                       //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract MSKYA is ERC721Creator {
    constructor() ERC721Creator("Maiskaya", "MSKYA") {}
}