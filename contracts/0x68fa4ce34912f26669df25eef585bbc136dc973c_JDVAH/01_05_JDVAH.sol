// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jpeg da Vinci Auction House
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                  //
//                                                                                                                                  //
//    Welcome to Jpeg da Vinci’s auction house - a place to unwind, dine, shine and spend a dime on Jpeg da Vinci’s finest work.    //
//                                                                                                                                  //
//                                                                                                                                  //
//    May the biggest loser win.                                                                                                    //
//                                                                                                                                  //
//    Jpeg da Vinci                                                                                                                 //
//                                                                                                                                  //
//                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JDVAH is ERC721Creator {
    constructor() ERC721Creator("Jpeg da Vinci Auction House", "JDVAH") {}
}