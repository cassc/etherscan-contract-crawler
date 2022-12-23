// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CX3-MOONING
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//     __  __   ___    ___   _   _  ___  _   _   ____   ____    ___   ____   ____           //
//    |  \/  | / _ \  / _ \ | \ | ||_ _|| \ | | / ___| |___ \  / _ \ |___ \ |___ \          //
//    | |\/| || | | || | | ||  \| | | | |  \| || |  _    __) || | | |  __) |  __) |         //
//    | |  | || |_| || |_| || |\  | | | | |\  || |_| |  / __/ | |_| | / __/  / __/          //
//    |_|  |_| \___/  \___/ |_| \_||___||_| \_| \____| |_____| \___/ |_____||_____|         //
//                                                                                          //
//                                                                                          //
//    CONSUMER EXPERIENCES IN WEB3                                                          //
//                                                                                          //
//    Mooning have been working for months to pioneer and deliver a new framework           //
//    for brands entering Web3.                                                             //
//                                                                                          //
//    We call it CX3.                                                                       //
//                                                                                          //
//    Over the last 18 months, Web3 has broken through to mainstream awareness,             //
//    but we’re still quite a long way from mainstream adoption.                            //
//                                                                                          //
//    CX3 focuses entirely on holistic, connected digital and physical consumer             //
//    experiences powered by Web3 technology to incrementally and steadily onboard          //
//    mainstream into the space.                                                            //
//                                                                                          //
//                                                                                          //
//    D2C + D2A                                                                             //
//                                                                                          //
//    Direct 2 Consumer and Direct 2 Avatar marketing and sales will                        //
//    eventually converge.                                                                  //
//                                                                                          //
//    DIRECT 2 IDENTITY - D2I                                                               //
//                                                                                          //
//    The future of Web3 has “Identity” at the core. Holistic marketing, sales              //
//    and consumer experiences will revolve around unique identities.                       //
//                                                                                          //
//    Web3 enables true digital ownership which means the bridge from physical              //
//    to digital is an inevitable reality.                                                  //
//                                                                                          //
//    Direct to Identity is a concept created and pioneered by Mooning. We                  //
//    believe this is the future of consumer engagement.                                    //
//                                                                                          //
//    In the future, identity will be interoperable across channels.                        //
//    There will be one identity which will be used everywhere.                             //
//                                                                                          //
//                                                                                          //
//    WHAT ARE CXTS?                                                                        //
//                                                                                          //
//    A collection of (chain agnostic) non-fungible tokens that are issued and used         //
//    to reward and create new digital and physical experiences.                            //
//                                                                                          //
//    That is what Mooning has coined CXTs.                                                 //
//    Consumer Experience Tokens.                                                           //
//                                                                                          //
//    WHY THIS IS GAME-CHANGING                                                             //
//                                                                                          //
//    Consumer Experience Tokens are the “currency” that incentivises the CX3 ecosystem.    //
//    By tokenising the consumer experience, CXTs can gamify and fuel interoperable         //
//    participation in a layered economy (Web2+ / D2I).                                     //
//                                                                                          //
//                                                                                          //
//    AUTHORS                                                                               //
//                                                                                          //
//    DAVID TAING                                                                           //
//    SAM FAIRWEATHER                                                                       //
//    LISA TEH                                                                              //
//                                                                                          //
//    2022                                                                                  //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract CX3 is ERC721Creator {
    constructor() ERC721Creator("CX3-MOONING", "CX3") {}
}