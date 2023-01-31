// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sanidad Design 1/1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                   //
//                                      .,ccccccccccccc;'.                                                                                                                                                           //
//                                     .dNMMWWWWWWWWWMMWNx.                                                                                                                                                          //
//                                     '0MM0c;;;;;;;:OMMMK;                                                                                                                                                          //
//                                     '0MMk.       .dWMMK;                                                                                                                                                          //
//                                     ,0MMk.       .dWMMK;                                                                                                                                                          //
//                                     '0MMk.        'ccc:.                                                                                                                                                          //
//                                     '0MMk.                                                                                                                                                                        //
//                                     .oNMNd.                                                                                                                                                                       //
//                                      .c0WMKl.     ,ddddddddddddl:'                                                                                                                                                //
//                                        .dXMWO;    oWMMMNXXXXXNWMMNO:.                                                                                                                                             //
//                                          ;OWMNd.  oWMMNo......,l0WMNd.                                                                                                                                            //
//                                           .cKWWKc.oWMMX:        .kWMX:                                                                                                                                            //
//                                             .dXMW0KWMMX:         cNMWl                                                                                                                                            //
//                                               ;OWMMMMMX:         cNMWl                                                                                                                                            //
//                                                .cKWMMMX:         cNMWl                                                                                                                                            //
//                                                  .dXMMX:         cNMWl                                                                                                                                            //
//                                                    ,kXK:         cNMWl                                                                                                                                            //
//                                                     .';.         cNMWl                                                                                                                                            //
//                                                                  cNMWl                                                                                                                                            //
//                                                                  cNMWl                                                                                                                                            //
//                                     .lxx:         ..             cNMWl                                                                                                                                            //
//                                     '0MMk.       .ok;.           cNMWl                                                                                                                                            //
//                                     '0MMk.       .dWNKd.         cNMWl                                                                                                                                            //
//                                     '0MMk.       .dWMMX:         :XMWl                                                                                                                                            //
//                                     '0MMk.       .dWMMX:         .lXWl                                                                                                                                            //
//                                     '0MM0l;;;;;;;cOMMMX:           'd:                                                                                                                                            //
//                                     .dNMMWWWWWWWWMMMMMX:                                                                                                                                                          //
//                                      .,ccccccccccl0WMMX:                                                                                                                                                          //
//                                                   oWMMX:                                                                                                                                                          //
//                                                   oWMMX:         ,c.                                                                                                                                              //
//                                                   oWMMX:         cX0:.                                                                                                                                            //
//                                                   oWMMX:         lWMX:                                                                                                                                            //
//                                                   oWMMX:       .cKMM0,                                                                                                                                            //
//                                                   oWMMWklllllox0NMW0;                                                                                                                                             //
//                                                   lNWWWWWWWWWWWNKkc.                                                                                                                                              //
//                                                   .,,,,,,,,,,,,..                                                                                                                                                 //
//                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SANIDAD1of1 is ERC721Creator {
    constructor() ERC721Creator("Sanidad Design 1/1", "SANIDAD1of1") {}
}