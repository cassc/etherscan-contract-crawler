// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CloudSeven.ExploringNewParadigms
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                              //
//                                                                                                              //
//    SMART CONTRACT DEPLOYED WITH: MANIFOLD.XYZ                                                                //
//    SMART CONTRACT NAME: CloudSeven.ExploringNewParadigms                                                     //
//    SMART CONTRACT SYMBOL: CSENP                                                                              //
//    SMART CONTRACT TYPE: ERC721                                                                               //
//    FIRST TIME IN USE: 2023                                                                                   //
//                                                                                                              //
//    ALL ARTWORK TOKENS DEPLOYED ON THIS SMART CONTRACT CONTAIN A 10% ROYALTY FEE                              //
//    ON EVERY SALE REGARDLESS OF WHETHER SALES PLATFORM SUPPORTS THIS AGREEMENT.                               //
//                                                                                                              //
//    BOTH SELLER AND COLLECTOR CAN BE HELD LIABLE FOR DAMAGE SUFFERED WHEN IGNORED.                            //
//                                                                                                              //
//    ALL USER RIGHTS ARE ALWAYS DESCRIBED IN A TOKEN SPECIFIC DOCUMENT ATTACHED                                //
//    TO THE NFT OF THE ARTWORK.                                                                                //
//                                                                                                              //
//    ARTWORK TOKENS DEPLOYED ON THIS SMART CONTRACT DO NOT GIVE PERMISSION                                     //
//    TO BE USED IN AI SOFTWARE UNLESS STATED OTHERWISE.                                                        //
//                                                                                                              //
//                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CSENP is ERC721Creator {
    constructor() ERC721Creator("CloudSeven.ExploringNewParadigms", "CSENP") {}
}