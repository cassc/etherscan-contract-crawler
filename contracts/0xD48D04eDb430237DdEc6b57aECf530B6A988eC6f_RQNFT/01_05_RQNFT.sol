// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ritchie's Open Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                                                                               //
//                                                                               //
//       dBBBBBb    dBP  dBBBBBBP dBBBP  dBP dBP dBP dBBBP dBP .dBBBBP           //
//           dBP                                           B   BP                //
//       dBBBBK'  dBP     dBP   dBP    dBBBBBP dBP dBBP        `BBBBb            //
//      dBP  BB  dBP     dBP   dBP    dBP dBP dBP dBP             dBP            //
//     dBP  dB' dBP     dBP   dBBBBP dBP dBP dBP dBBBBP      dBBBBP'             //
//                                                                               //
//         dBBBP dBBBBBb    dBBBP dBBBBBb  dBBBBBBP dBP dBBBBP dBBBBb.dBBBBP     //
//                   dBP               BB              dB'.BP     dBPBP          //
//       dBP     dBBBBK'  dBBP     dBP BB   dBP   dBP dB'.BP dBP dBP `BBBBb      //
//      dBP     dBP  BB  dBP      dBP  BB  dBP   dBP dB'.BP dBP dBP     dBP      //
//     dBBBBP  dBP  dB' dBBBBP   dBBBBBBB dBP   dBP dBBBBP dBP dBP dBBBBP'       //
//                                                                               //
//                                                                               //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////


contract RQNFT is ERC1155Creator {
    constructor() ERC1155Creator("Ritchie's Open Editions", "RQNFT") {}
}