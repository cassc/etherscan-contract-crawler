// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The MiddleVerse
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//    M""""""""M M""MMMMM""MM MM""""""""`M    M"""""`'"""`YM M""M M""""""'YMM M""""""'YMM M""MMMMMMMM MM""""""""`M M""MMMMM""M MM""""""""`M MM"""""""`MM MP""""""`MM MM""""""""`M     //
//    Mmmm  mmmM M  MMMMM  MM MM  mmmmmmmM    M  mm.  mm.  M M  M M  mmmm. `M M  mmmm. `M M  MMMMMMMM MM  mmmmmmmM M  MMMMM  M MM  mmmmmmmM MM  mmmm,  M M  mmmmm..M MM  mmmmmmmM     //
//    MMMM  MMMM M         `M M`      MMMM    M  MMM  MMM  M M  M M  MMMMM  M M  MMMMM  M M  MMMMMMMM M`      MMMM M  MMMMP  M M`      MMMM M'        .M M.      `YM M`      MMMM     //
//    MMMM  MMMM M  MMMMM  MM MM  MMMMMMMM    M  MMM  MMM  M M  M M  MMMMM  M M  MMMMM  M M  MMMMMMMM MM  MMMMMMMM M  MMMM' .M MM  MMMMMMMM MM  MMMb. "M MMMMMMM.  M MM  MMMMMMMM     //
//    MMMM  MMMM M  MMMMM  MM MM  MMMMMMMM    M  MMM  MMM  M M  M M  MMMM' .M M  MMMM' .M M  MMMMMMMM MM  MMMMMMMM M  MMP' .MM MM  MMMMMMMM MM  MMMMM  M M. .MMM'  M MM  MMMMMMMM     //
//    MMMM  MMMM M  MMMMM  MM MM        .M    M  MMM  MMM  M M  M M       .MM M       .MM M         M MM        .M M     .dMMM MM        .M MM  MMMMM  M Mb.     .dM MM        .M     //
//    MMMMMMMMMM MMMMMMMMMMMM MMMMMMMMMMMM    MMMMMMMMMMMMMM MMMM MMMMMMMMMMM MMMMMMMMMMM MMMMMMMMMMM MMMMMMMMMMMM MMMMMMMMMMM MMMMMMMMMMMM MMMMMMMMMMMM MMMMMMMMMMM MMMMMMMMMMMM     //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
//                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MDV is ERC721Creator {
    constructor() ERC721Creator("The MiddleVerse", "MDV") {}
}