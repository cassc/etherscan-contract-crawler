// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BENIBISCHOF.DGTL.V1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                                                                               //
//    SMART CONTRACT BY: BENI BISCHOF                                            //
//    DEPLOYED WITH: MANIFOLD.XYZ                                                //
//    SMART CONTRACT NAME: BENIBISCHOF.DGTL.V1                                   //
//    SMART CONTRACT TYPE: ERC721                                                //
//    SMART CONTRACT SYMBOL: BBD1                                                //
//    FIRST TIME IN USE: 2022                                                    //
//                                                                               //
//    FIRST DIGITAL SUPPORT BY:                                                  //
//    PLUS-ONE GALLERY (ANTWERP, BE) & ARTIST PROOF STUDIO (ANTWERP, BE)         //
//                                                                               //
//    CONTRACT PURPOSE:                                                          //
//    THE CONTRACT HAS ITS PURPOSE TO REGISTER (DIGITAL) ARTWORKS                //
//    BY SWISS ARTIST BENI BISCHOF AND MAKE ARTWORKS READY FOR DISTRIBUTION.     //
//                                                                               //
//    TOKENS DEPLOYED ON THIS CONTRACT GIVE TOKEN OWNERS CERTAIN RIGHTS ON       //
//    THE USE OF THE ARTWORK IN THE VIRTUAL WORLD.                               //
//                                                                               //
//    THESE RIGHTS ARE ALWAYS DESCRIBED IN A TOKEN SPECIFIC DOCUMENT ATTACHED    //
//    TO THE NFT OF THE ARTWORK.                                                 //
//                                                                               //
//    PLEASE CONTACT THE ARTIST OR HIS REPRESENTATIVE GALLERY                    //
//    IN CASE OF DOUBT ABOUT THE AUTHENTICITY OF THE CONTRACT AND ITS TOKENS.    //
//                                                                               //
//    MAIL: [email protected]                                            //
//    PORTFOLIO: WWW.BENIBISCHOF.CH                                              //
//                                                                               //
//    MAIL: [email protected]                                                     //
//    PORTFOLIO: WWW.PLUS-ONE.BE                                                 //
//                                                                               //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////


contract BBD1 is ERC721Creator {
    constructor() ERC721Creator("BENIBISCHOF.DGTL.V1", "BBD1") {}
}