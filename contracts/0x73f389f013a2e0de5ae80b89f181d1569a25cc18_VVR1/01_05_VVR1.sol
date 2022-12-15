// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VICTORVERHELST.RPRDCTN.V1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//    SMART CONTRACT BY: VICTOR VERHELST                                             //
//    DEPLOYED WITH: MANIFOLD.XYZ                                                    //
//    SMART CONTRACT NAME: VICTORVERHELST.RPRDCTN.V1                                 //
//    SMART CONTRACT TYPE: ERC721                                                    //
//    SMART CONTRACT SYMBOL: VVR1                                                    //
//    FIRST TIME IN USE: 2022                                                        //
//                                                                                   //
//    FIRST DIGITAL SUPPORT BY:                                                      //
//    PLUS-ONE GALLERY (ANTWERP, BE) & ARTIST PROOF STUDIO (ANTWERP, BE)             //
//                                                                                   //
//    CONTRACT PURPOSE:                                                              //
//    THE CONTRACT HAS ITS PURPOSE TO REGISTER (DIGITAL) ARTWORKS                    //
//    BY BELGIAN ARTIST VICTOR VERHELST AND MAKE ARTWORKS READY FOR DISTRIBUTION.    //
//                                                                                   //
//    TOKENS DEPLOYED ON THIS CONTRACT GIVE TOKEN OWNERS CERTAIN RIGHTS              //
//    TO REPRODUCE THE ARTWORK IN THE PHYSICAL WORLD AND GIVE TOKEN OWNERS           //
//    CERTAIN RIGHTS ON THE USE OF THE ARTWORK IN THE VIRTUAL WORLD.                 //
//                                                                                   //
//    THESE RIGHTS ARE ALWAYS DESCRIBED IN A TOKEN SPECIFIC DOCUMENT ATTACHED        //
//    TO THE NFT OF THE ARTWORK.                                                     //
//                                                                                   //
//    PLEASE CONTACT THE ARTIST IN CASE OF DOUBT ABOUT THE AUTHENTICITY              //
//    OF THE CONTRACT AND ITS TOKENS.                                                //
//                                                                                   //
//    MAIL: [email protected]                                                //
//    PORTFOLIO: WWW.VICTORVERHELST.BE                                               //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract VVR1 is ERC721Creator {
    constructor() ERC721Creator("VICTORVERHELST.RPRDCTN.V1", "VVR1") {}
}