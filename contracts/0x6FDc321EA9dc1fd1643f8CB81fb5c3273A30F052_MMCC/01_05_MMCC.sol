// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MIMI collaborative collection
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//    (JJJJJJ,            .JJJJJJ.  .kMMMNa. .JJJJJJ,            .JJJJJJ,    .JJJJJJJJJ    //
//    dMMMMMMb           .MMMMMMM_ -MMMMMMM# .MMMMMMM,          .MMMMMMM]   .MMMMMMMMF     //
//    dMMMMMMM[          MMMMMMMM! MMMMMMMMF .MMMMMMMb          (MMMMMMM]   JMMMMMMMD      //
//    dMMMMMMMN.        -MMMMMMMM! (MMMMM#^  .MMMMMMMM[        .MMMMMMMM]  .MMMMMMM3       //
//    dMMM] (MMb       .MMM  MMMM_   .," ..  .MMM# .MMN.       MMM[ dMMM] .MMMMMMMNM#'     //
//    dMMM] (MMMc      dMMM  MMMM! .db.MMMF  .MMM# .MMMb      .MMM[ dMMM] -MY"~JMMM"       //
//    dMMM] (MMMN.    .MMMM  MMMM! ."= dMMN, .MMM# .MMMM;    .MMMM\ dMMM]    .MMM#`        //
//    dMMM] ,"4MMb   .MMM""  MMMM;    .MMMMF ,MMM#  ?"MMN    dMMY=  dMMM]   .MMMN([email protected]       //
//    dMMM]   .MMM,  dMMN    MMMM_   .MMMMM' .MMM#   .MMMb  .MMM}   dMMM]  .MMMMMM$        //
//    dMMM]   .MMMN .MMMN    MMMM!  [email protected]   .MMM#   .MMMM,.MMMM:   dMMM] .M9"dMM'         //
//    dMMM]   .74MMNMM#77    MMMM! .MMMMMM[  .MMM#    ("MMNdMM"=    dMMM]    [email protected]           //
//    dMMM]     ,MMMMM#      MMMM; (MMMMMM^  ,MMM#      MMMMMM!     dMMM]   .MD            //
//    ?777'     .77777=      7777`  7MMH"`   .777^       ?""=       (777'   J^             //
//                                                                                         //
//                                                                                         //
//      ..NMMMNg,       .+MMMMN&.     .N-        .N;            (Np       qNNNNNNgJ.       //
//    .dM"     (HN,   .M#^     ?MN.   (M}        -M)           .MWM,      M#     .HM,      //
//    dM\        !   .M#        ,Mb   (M}        -M)          .MF WN.     M#     .dM!      //
//    MM             .MF         MM   (M}        -M)          M#  .Mb     MMMMMMMMN,       //
//    MM,        gJ  .MN        .MF   (M}        -M)         JMMMMMMM]    M#      (Mb      //
//    .MN,     .dM^   ?Mm.     .M#!   (M}        -M)        .M$     4M,   M#      .MF      //
//      ?HMNNNM#"       TMNNggM#=     (MMMMMMMF  [email protected] .MF       MN   MMMMMMMM#"       //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////


contract MMCC is ERC1155Creator {
    constructor() ERC1155Creator("MIMI collaborative collection", "MMCC") {}
}