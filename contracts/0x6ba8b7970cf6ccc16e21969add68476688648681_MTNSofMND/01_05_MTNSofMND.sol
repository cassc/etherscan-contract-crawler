// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FromTheMountainsOfOurMind
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//                                                                             //
//    M"""""`'"""`YM   dP                        MMP"""""YMM .8888b            //
//    M  mm.  mm.  M   88                        M' .mmm. `M 88   "            //
//    M  MMM  MMM  M d8888P 88d888b. .d8888b.    M  MMMMM  M 88aaa             //
//    M  MMM  MMM  M   88   88'  `88 Y8ooooo.    M  MMMMM  M 88                //
//    M  MMM  MMM  M   88   88    88       88    M. `MMM' .M 88                //
//    M  MMM  MMM  M   dP   dP    dP `88888P'    MMb     dMM dP                //
//    MMMMMMMMMMMMMM                             MMMMMMMMMMM                   //
//                                                                             //
//    MMP"""""YMM                      M"""""`'"""`YM oo                dP     //
//    M' .mmm. `M                      M  mm.  mm.  M                   88     //
//    M  MMMMM  M dP    dP 88d888b.    M  MMM  MMM  M dP 88d888b. .d888b88     //
//    M  MMMMM  M 88    88 88'  `88    M  MMM  MMM  M 88 88'  `88 88'  `88     //
//    M. `MMM' .M 88.  .88 88          M  MMM  MMM  M 88 88    88 88.  .88     //
//    MMb     dMM `88888P' dP          M  MMM  MMM  M dP dP    dP `88888P8     //
//    MMMMMMMMMMM                      MMMMMMMMMMMMMM                          //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


contract MTNSofMND is ERC1155Creator {
    constructor() ERC1155Creator("FromTheMountainsOfOurMind", "MTNSofMND") {}
}