// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FOR THE CULTURE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    I'm Nuwan Shilpa Hennayake, a Psychedelic Visionary Artist from Sri Lanka.                    //
//    I create Digital Mind Trips inspired by Liberal Spiritual Dimensions                          //
//                                                                                                  //
//    The NFTs in this contract are created for the advancement and celebration of web3 culture!    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract CULT is ERC721Creator {
    constructor() ERC721Creator("FOR THE CULTURE", "CULT") {}
}