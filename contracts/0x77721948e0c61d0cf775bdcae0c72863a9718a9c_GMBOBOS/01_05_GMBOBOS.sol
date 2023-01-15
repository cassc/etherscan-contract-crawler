// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GeoMetric Bobos
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                  //
//                                                                                                                                  //
//       .aMMMMP dMMMMMP .aMMMb  dMMMMMMMMb  dMMMMMP dMMMMMMP dMMMMb  dMP .aMMMb         dMMMMb  .aMMMb  dMMMMb  .aMMMb  .dMMMb     //
//      dMP"    dMP     dMP"dMP dMP"dMP"dMP dMP        dMP   dMP.dMP amr dMP"VMP        dMP"dMP dMP"dMP dMP"dMP dMP"dMP dMP" VP     //
//     dMP MMP"dMMMP   dMP dMP dMP dMP dMP dMMMP      dMP   dMMMMK" dMP dMP            dMMMMK" dMP dMP dMMMMK" dMP dMP  VMMMb       //
//    dMP.dMP dMP     dMP.aMP dMP dMP dMP dMP        dMP   dMP"AMF dMP dMP.aMP        dMP.aMF dMP.aMP dMP.aMF dMP.aMP dP .dMP       //
//    VMMMP" dMMMMMP  VMMMP" dMP dMP dMP dMMMMMP    dMP   dMP dMP dMP  VMMMP"        dMMMMP"  VMMMP" dMMMMP"  VMMMP"  VMMMP"        //
//                                                                                                                                  //
//                                                                                                                                  //
//                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GMBOBOS is ERC721Creator {
    constructor() ERC721Creator("GeoMetric Bobos", "GMBOBOS") {}
}