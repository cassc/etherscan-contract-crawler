// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OpenSad
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//     OOOOO                          SSSSS               dd                                                                            //
//    OO   OO pp pp     eee  nn nnn  SS        aa aa      dd                                                                            //
//    OO   OO ppp  pp ee   e nnn  nn  SSSSS   aa aaa  dddddd                                                                            //
//    OO   OO pppppp  eeeee  nn   nn      SS aa  aaa dd   dd                                                                            //
//     OOOO0  pp       eeeee nn   nn  SSSSS   aaa aa  dddddd  NFT Project                                                               //
//    Consider this a Coin with a NFT Attached as a prettier alternative to just holding a coin                                         //
//    This project started because of a community confused and sad That after all the business we have given to                         //
//    OPENSEE. Still no release of a token. Many other smaller marketplaces have rewarded us. But still nothing from.. you know who.    //
//    So here is the OpenSad Dao Project                                                                                                //
//    We will go from here as a community to decide next steps for the project                                                          //
//    Voting,Artists,Creator,NFTCOMMUNITY Tools think of this as also a Community Government                                            //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OPSad is ERC721Creator {
    constructor() ERC721Creator("OpenSad", "OPSad") {}
}