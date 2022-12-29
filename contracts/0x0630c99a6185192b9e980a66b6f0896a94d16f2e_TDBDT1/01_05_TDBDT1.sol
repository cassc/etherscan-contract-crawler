// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THOMASDEBEN.DGTLTWN.V1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                             //
//                                                                                             //
//    SMART CONTRACT BY: THOMAS DE BEN                                                         //
//    DEPLOYED WITH: MANIFOLD.XYZ                                                              //
//    SMART CONTRACT NAME: THOMASDEBEN.DGTLTWN.V1                                              //
//    SMART CONTRACT SYMBOL: TDBDT1                                                            //
//    SMART CONTRACT TYPE: ERC721                                                              //
//    FIRST TIME IN USE: 2022                                                                  //
//                                                                                             //
//    CONTRACT PURPOSE:                                                                        //
//    THE CONTRACT HAS ITS PURPOSE TO REGISTER (DIGITAL) ARTWORKS                              //
//    BY BELGIAN ART CREATIVE THOMAS DE BEN AND MAKE ARTWORKS READY FOR DISTRIBUTION.          //
//                                                                                             //
//    TOKENS DEPLOYED ON THIS SMART CONTRACT GIVE TOKEN OWNERS CERTAIN RIGHTS                  //
//    ON THE USE OF BOTH PHYSICAL AND DIGITAL ARTWORKS IN THE REAL AND VIRTUAL WORLD.          //
//                                                                                             //
//    ALL ARTWORK TOKENS CONTAIN A 10% ROYALTY FEE ON EVERY SALE (UNLESS STATED OTHERWISE)     //
//    REGARDLESS OF WHETHER SALES PLATFORM SUPPORTS THIS AGREEMENT.                            //
//    BOTH SELLER AND COLLECTOR CAN BE HELD LIABLE FOR DAMAGE SUFFERED WHEN IGNORED.           //
//                                                                                             //
//    ARTWORK TOKENS DEPLOYED ON THIS SMART CONTRACT - WHEN CONTAINING A PHYSICAL EDITION -    //
//    ALWAYS MATCH TOGETHER AND MAY NOT BE DISTRIBUTED OR SOLD SEPARATELY                      //
//    UNLESS STATED OTHERWISE.                                                                 //
//                                                                                             //
//    ALL RIGHTS ARE ALWAYS DESCRIBED IN A TOKEN SPECIFIC DOCUMENT ATTACHED                    //
//    TO THE NFT OF THE ARTWORK.                                                               //
//                                                                                             //
//    ARTWORK TOKENS DEPLOYED ON THIS SMART CONTRACT DO NOT GIVE PERMISSION TO BE USED         //
//    IN AI SOFTWARE UNLESS STATED OTHERWISE.                                                  //
//                                                                                             //
//    PLEASE CONTACT THE ARTIST IN CASE OF DOUBT ABOUT THE AUTHENTICITY                        //
//    OF THE CONTRACT AND ITS TOKENS.                                                          //
//                                                                                             //
//    MAIL: [email protected]                                                               //
//    PORTFOLIO: WWW.THOMASDEBEN.COM                                                           //
//                                                                                             //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////


contract TDBDT1 is ERC721Creator {
    constructor() ERC721Creator("THOMASDEBEN.DGTLTWN.V1", "TDBDT1") {}
}