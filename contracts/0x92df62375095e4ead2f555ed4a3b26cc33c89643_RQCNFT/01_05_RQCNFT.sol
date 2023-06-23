// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ritchie Q Creates
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//       dBBBBBb    dBP dBBBBBBP dBBBP  dBP dBP dBP dBBBP     dBBBBP     dBBBP dBBBBBb    dBBBP dBBBBBb  dBBBBBBP dBBBP.dBBBBP    //
//           dBP                                             dB'.BP                dBP               BB                BP         //
//       dBBBBK'  dBP    dBP   dBP    dBBBBBP dBP dBBP      dB'.BP     dBP     dBBBBK   dBBP     dBP BB   dBP   dBBP   `BBBBb     //
//      dBP  BB  dBP    dBP   dBP    dBP dBP dBP dBP       dB'.BB     dBP     dBP  BB  dBP      dBP  BB  dBP   dBP        dBP     //
//     dBP  dB' dBP    dBP   dBBBBP dBP dBP dBP dBBBBP    dBBBB'B    dBBBBP  dBP  dB' dBBBBP   dBBBBBBB dBP   dBBBBP dBBBBP'      //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RQCNFT is ERC721Creator {
    constructor() ERC721Creator("Ritchie Q Creates", "RQCNFT") {}
}