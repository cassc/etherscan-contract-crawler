// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hangover Brunch
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//    Hosts:                                             //
//    RenRen, FrankyWWL, Voncrossfit                     //
//                                                       //
//    Artist:                                            //
//    CaptainZookit                                      //
//                                                       //
//    Date:                                              //
//    June 24, 2023                                      //
//    12:00 PM - 3:00 PM                                 //
//                                                       //
//    Where:                                             //
//    3000 S Las Vegas Blvd, Las Vegas, NV 89109, USA    //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract AZUKIBRUNCH is ERC721Creator {
    constructor() ERC721Creator("Hangover Brunch", "AZUKIBRUNCH") {}
}