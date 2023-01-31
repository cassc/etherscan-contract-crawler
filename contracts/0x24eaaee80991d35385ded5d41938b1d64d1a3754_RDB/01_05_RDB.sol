// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MOVING GM
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//                                                                                          //
//       .aMMMMP dMMMMMMMMb  .aMMMMP dMMMMMMMMb         dMMMMb  .aMMMb  dMMMMb  dMP dMP     //
//      dMP"    dMP"dMP"dMP dMP"    dMP"dMP"dMP        dMP"dMP dMP"dMP dMP"dMP dMP.dMP      //
//     dMP MMP"dMP dMP dMP dMP MMP"dMP dMP dMP        dMMMMK" dMMMMMP dMMMMK"  VMMMMP       //
//    dMP.dMP dMP dMP dMP dMP.dMP dMP dMP dMP        dMP.aMF dMP dMP dMP.aMF dA .dMP        //
//    VMMMP" dMP dMP dMP  VMMMP" dMP dMP dMP        dMMMMP" dMP dMP dMMMMP"  VMMMP"         //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract RDB is ERC1155Creator {
    constructor() ERC1155Creator("MOVING GM", "RDB") {}
}