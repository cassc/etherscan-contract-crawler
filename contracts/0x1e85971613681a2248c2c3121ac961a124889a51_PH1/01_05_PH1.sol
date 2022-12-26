// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Punk Hunter 1/1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//    A place to share some of PunkHunter.eth most treasured pieces.                                                                                                               //
//                                                                                                                                                                                 //
//    Since a young age, PunkHunter.eth has been around art, as the passion and desire for art returns as a result of collecting inspiring work. So does the desire to make art    //
//                                                                                                                                                                                 //
//    May the inspirer be the inspired.                                                                                                                                            //
//                                                                                                                                                                                 //
//    PunkHunter.eth                                                                                                                                                               //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PH1 is ERC721Creator {
    constructor() ERC721Creator("Punk Hunter 1/1", "PH1") {}
}