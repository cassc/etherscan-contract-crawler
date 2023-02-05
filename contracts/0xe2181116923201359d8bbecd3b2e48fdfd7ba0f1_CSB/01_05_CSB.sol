// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 99 Luftballons
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    99 Kriegsminister                      //
//    Streichholz und Benzinkanister         //
//    Hielten sich für schlaue Leute         //
//    Witterten schon fette Beute            //
//    Riefen, „Krieg!“, und wollten Macht    //
//    Mann, wer hätte das gedacht?           //
//    Dass es einmal so weit kommt           //
//    Wegen 99 Luftballons                   //
//                                           //
//                                           //
///////////////////////////////////////////////


contract CSB is ERC721Creator {
    constructor() ERC721Creator("99 Luftballons", "CSB") {}
}