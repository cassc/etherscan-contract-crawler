// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Grief and hope in the eyes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//    It was all grief, pain, fear, despair, exhaustion, hope and rebellion that was     //
//    read through the eyes at the moment, and how it described what has happened!       //
//                                                                                       //
//    This NFT is created from my original pastel painting which is dedicated for        //
//    the children who are deeply affected by the catastrophic earthquakes in Turkey.    //
//    The revenue generated from this NFT will be donated to ACEV (Mother and Child      //
//    Education Foundation) to be used in earthquake relief.                             //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract TEH is ERC1155Creator {
    constructor() ERC1155Creator("Grief and hope in the eyes", "TEH") {}
}