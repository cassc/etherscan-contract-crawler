// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MrsPepe Community Pillars
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//    This contract is the MrsPepe Community fundraiser, created by           //
//    and for the community. Its purpose is to empower the community          //
//    by offering direct and transparent support to vital aspects, such       //
//    as Marketing, Development, and Security. In doing so, it serves         //
//    as a catalyst for the overall success of our community.                 //
//                                                                            //
//    The NFTs minted through this contract will possess distinct category    //
//    traits and detailed descriptions, symbolizing the specific pillars      //
//    and initiatives they contribute to. Additionally, they may contain      //
//    other traits that can be utilized in future community utilities.        //
//                                                                            //
//    ~Dank Croaker~                                                          //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract MRSPC is ERC1155Creator {
    constructor() ERC1155Creator("MrsPepe Community Pillars", "MRSPC") {}
}