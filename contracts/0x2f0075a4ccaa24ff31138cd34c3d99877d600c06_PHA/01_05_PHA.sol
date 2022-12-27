// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PunkHunter Auction House
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                         //
//                                                                                                                         //
//    What better place to curate PunkHunter.eth finest work, than in the gladiators arena of nft’s, the auction house.    //
//                                                                                                                         //
//    Welcome to the auction house of PunkHunter.                                                                          //
//                                                                                                                         //
//    Be careful, be wise, be calm.                                                                                        //
//                                                                                                                         //
//    Enjoy life to the fullest.                                                                                           //
//                                                                                                                         //
//    PunkHunter.eth                                                                                                       //
//                                                                                                                         //
//                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PHA is ERC721Creator {
    constructor() ERC721Creator("PunkHunter Auction House", "PHA") {}
}