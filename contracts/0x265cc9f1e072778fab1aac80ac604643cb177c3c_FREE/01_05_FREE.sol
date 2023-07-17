// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FREEDOM BOYS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//      `                jMMMMMMp (MMNNaJ  .NMMMMMN .gMMMMMN, gMMN&,    .MMMN&  .MN   .Mb                    //
//         `  `  `  `  ` MM#????` MM#7TMMN JMM=???! ,MMF???! .MMYWMMN. .MMDTMM] JMM| [email protected]  `  `  `  `  `     //
//                       MMF      [email protected]  dMM JMM`     ,MM]     ,MM} ,MMb MM#  MMN JMMb ([email protected]                    //
//      `    `    `      MMF      [email protected] .MMF JMM-...  .MM].... ,MM}  MMN [email protected]  dMM [email protected]       `    `       //
//        `    `    `  ` MMMMMMM] MMMMMMD  (MMMMMMF .MMMMMM# ,MM}  dMN [email protected]  gMM ([email protected]  `  `    `    `    //
//                       MM#!!!   MM#TMMb  (MM.     .MM]     ,MM}  dMN MMN  JMM [email protected]                    //
//      `   `   `  `     [email protected]      MM# MMM; (MM_     .MM]     ,MM} .MMF dMM. gMM`,MMMMMMM#   `   `   `  `     //
//                   `  `[email protected]      MM# ,[email protected] (MM} ...  MMb....,,MMnJMMM' (MM] MMM ,M#MMMdM#         `          //
//                       [email protected]      MM#  MMM.,MMMMMMM\ MMMMMMMD.MMMMM#'   MMM-MM# ,M#MMMJM#                    //
//                       [email protected]      MM#  JMM\.H""!                        -MMMMM] .MNdMM(M#                    //
//                       [email protected]      MM#   "!    ....JgggNNNNNggg+(....      7"H"  .MN(MM(M#                    //
//                       MM#      T9`  ..(gMM"""7~(...........(?7""HMMN+..       M#.M#(M#                    //
//                       MM#       ..gM""`..JgMMMMMMMMMMMMMMMMMMMMNaJ..?TMMN,.      ?=.M#                    //
//                       ?B!     .M#" ..MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN,._TMN,       .`                    //
//                             .M"  .MMMM#!   ?UMM"   ?MF [email protected]`,MM"` _TMMMMN, (WN,                           //
//                           .MD  .MMMMMMF .MN  MF .M, JN. UM` JM` .N,.dMMMMMN. (Mh.                         //
//                           MF  .MMMMMMM] .MD  d} JMb .MN  ^ .MM. UMMMMMMMMMMN, .Mb                         //
//                          .M`  MMMMMMMM]     HM} [email protected] .MMb  .MMMN. .TMMMMMMMMMb  JM.                        //
//                          .M,  MMMMMMMM] .Mm  M] ([email protected] .MMM` MMMMMMMe  MMMMMMMMF  JM`                        //
//                           WN. ,MMMMMMMF .MM' Jb .MF .MMM` MMMb .MM` MMMMMMM#` .MF                         //
//                            UN, [email protected]  !  .MM,   .MMMM` MMMb  .` .MMMMMMD  .MD                          //
//                             (MN, .YMMMMNNMMMMMMMMMMMMMMMNMMMMMMMNMMMMMMM" ..M#'                           //
//                               ,YMN,.(TMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM#"`..MMD`                             //
//                                  _TMMN&..?""MMMMMMMMMMMMMMMMMMH""!..+MM#"`                                //
//                                       ?THMMMNgg(.....(.....(&gMMMM""^                                     //
//                                              _?7"""""""""""7!`                                            //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FREE is ERC721Creator {
    constructor() ERC721Creator("FREEDOM BOYS", "FREE") {}
}