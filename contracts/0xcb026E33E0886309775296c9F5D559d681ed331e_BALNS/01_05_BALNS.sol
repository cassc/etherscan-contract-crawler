// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BALLOONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                             //
//                                                                                             //
//      -MMMMMNa,     MN.    MF      db      ..NMHHNa,    ..NMHHNa.   jN,    .N   .gH"HNa.     //
//      (#     d#    [email protected]    MF      d#     .M$     ,Mp  .M$     ,Mp  dFMp   .N  .M{    XE     //
//      (NJJJJgM^   .M` Mb   MF      d#     M#       JM. M#       JM  dF TN. ,N   TMNgJ.,      //
//      (#     TN. .MNggdM,  MF      d#     MN       (#  MN       (#  dF  (N,.N   .    ?WN     //
//      (#     .M'.MF    dN. MF      d#     ,Mb.    .M3  ,Mb.    .M3  [email protected]   .WNN  qN,    (M`    //
//      ("""""""! d9      T5 T"""""9 7"""""B  ?"HMM""      ?"HMM"=    ?9     T9   ,THMM""      //
//                                                                                             //
//                                                                                             //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////


contract BALNS is ERC1155Creator {
    constructor() ERC1155Creator("BALLOONS", "BALNS") {}
}