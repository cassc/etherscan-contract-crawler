// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Time of Metaverse
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                         //
//                                                                                                         //
//    ToM (Time of Metaverse)                                                                              //
//    ToM is the only decentralise time system that offers a true universal time for all web users.        //
//    —                                                                                                    //
//    Resume : The invention described in this patent concerns a new universal and decentralized           //
//    time system for WEB users. This system is intended to allow all web users to use the same time       //
//    that is not based on the time of the sun, but on blockchain technology.                              //
//    —                                                                                                    //
//    Introduction : Web and metaverse users need a time system to synchronize activities, schedule        //
//    events, measure the duration of an event,synchronize systems and enhance our digital                 //
//    identities. The problem is that the UTC time system:                                                 //
//    Is based on a time zone system ; which forces users to convert depending on where they are           //
//    located. This causes confusion and doubt for many users.                                             //
//    Based on the time of the sun ; depending on where you are on the planet and which makes no           //
//    sense in a virtual world that has its own rules and brings together people from around the           //
//    world.                                                                                               //
//    —                                                                                                    //
//    Description : The invention described in this patent aims at providing a universal and               //
//    decentralized time system that allows web and metaverse users to use a common and identical          //
//    time wherever they are. Like any time system, ToM relies on :                                        //
//    Stable and accurate time references. We imagine using data related to the block mining of            //
//    the Bitcoin and Ethereum blockchains.                                                                //
//    Cultural and historical references. We see the creation of the Bitcoin blockchain as the             //
//    reference point for WEB3 users and thus as an obvious starting point for the ToM time system.        //
//    —                                                                                                    //
//    Right holder: The invention described in this document was born of a discussion on Monday,           //
//    January 16, 2023, between Dimitri Serge Daniloff, born on December 13, 1970, in Clermont (Oise),     //
//    France, and Valentin Vincent Tabary, born on October 11, 1991, in Lille (Nord), France. This         //
//    patent attests the paternity and the property of this idea to the two persons mentioned earlier:     //
//    Dimitri Daniloff and Valentin Tabary.                                                                //
//                                                                                                         //
//                                                                                                         //
//                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ToM is ERC721Creator {
    constructor() ERC721Creator("Time of Metaverse", "ToM") {}
}