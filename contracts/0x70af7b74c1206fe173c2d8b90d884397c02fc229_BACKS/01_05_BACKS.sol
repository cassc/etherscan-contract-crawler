// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BananaChecks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//        dMMMMb  .aMMMb  .aMMMb  dMP dMP .dMMMb      //
//       dMP"dMP dMP"dMP dMP"VMP dMP.dMP dMP" VP      //
//      dMMMMK" dMMMMMP dMP     dMMMMK"  VMMMb        //
//     dMP.aMF dMP dMP dMP.aMP dMP"AMF dP .dMP        //
//    dMMMMP" dMP dMP  VMMMP" dMP dMP  VMMMP"         //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract BACKS is ERC721Creator {
    constructor() ERC721Creator("BananaChecks", "BACKS") {}
}