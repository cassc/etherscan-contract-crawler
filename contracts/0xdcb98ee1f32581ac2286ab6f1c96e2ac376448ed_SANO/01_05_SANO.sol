// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sano Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//                                                  .......                                                 //
//                                        ...&SANOS""""""""""SANOSa(..                                      //
//                                   .(SAN""O                      ?S"ANOs.                                 //
//                               .sAN"'                                  ?SANo.                             //
//                           ..SA"`                                          (SAN,.                         //
//                         .S#"                                                 .SAN,                       //
//                      .SAN`                                                      .SAN.                    //
//                    .sA=                                                            SAn.                  //
//                  .s#^                                                                ?Sa.                //
//                 .S=                                                                    SAn               //
//               .SA   .SA,                                                           .s.  .SA.             //
//              .S^    .MMMMn.                                                     .aMMM`    SA,            //
//            .SA`      nMMMMMo.                                                ..MMMMMA      ,Sa           //
//           .SA        (MMMMMMMS,                                            .MMMMMMMM!       .SA          //
//          .SA         .MMMMMMMMMMa,                                      .nMMMMMMMMMN          Sa         //
//         .SA           OMMMMMMMMMMMN,                                 ..MMMMMMMMMMMM\          .Sa        //
//         S#            -MMMMMMMMMMMMMMo.                            .MMMMMMMMMMMMO""            ,Sa       //
//        .S'            .MMMMMMMMMMMMMMMMS,                       .oMMMMMMMMMMMMS                 (S,      //
//       .SA              sMMMMMMMMMMMMMMMMMMa.                  .MMMMMMMMMMMMMMM                   Sa      //
//       (#               .MMMMMMMMMMMMMMMMMMMMN,             .+MMMMMMMMMMMMMMMMM[                  .S;     //
//       SA                MMMMMMMMMMMMMMMMMMMMMMMo.        .MMMMMMMMMMMMMMMMMMMMMN,                 Sa     //
//      .SA                (MMMMMMMMMMMMMMMMMMMMMMMMS,    .MMMMMMMMMMMMMMMMMMMMMMMMO                 SA     //
//      S#                 .MMMMMMMMMMMMMMMMMMMMMMMM#"..S.?SMMMMMMMMMMMMMMMMMMMMMMM>                 .S)    //
//      SA                  MMMMMMMMMMMMMMMMMMMM#"s.aMMMMMMa..AWMMMMMMMMMMMMMMMMMM#                   S]    //
//      SA                  (MMMMMMMMMMMMMMMS=-.oMMMMMMMMMMMMMNO,.NMMMMMMMMMMMMMMMS                   Sa    //
//      SA                  .MMMMMMMMMMMO=..nMMMMMMMMMMMMMMMMMMMMMS,.?OMMMMMMMMMM#                    Sa    //
//      SA                   AMMMMMMN^..aMMMMMMMMMMMMMMMMMMMMMMMMMMMMMa.."SMMMMMMA                    S]    //
//      SA                   -MM"^..sMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNO..ANMM!                   .S]    //
//      SA                     .nMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMS,.                     .S>    //
//      .S;                    AMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM~                    S#     //
//       Sa                      ?SMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM"`                     SA     //
//       -S.                        ?OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM#"                        .SA     //
//        Sa                           ?NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM#=                          .SA      //
//        .S[                             ?AMMMMMMMMMMMMMMMMMMMMMMMMS^                             S#       //
//         ?S,                               ?SMMMMMMMMMMMMMMMMMM"!                               .S'       //
//          SA.                                 (OMMMMMMMMMMM#"                                  .Sa        //
//           SA.                                    NMMMMMA^                                    .Sa         //
//            SA,                                      _`                                      .SA          //
//             ?S,                  .SSS.      .,      N      .N    ..oooo..                  .S^           //
//              ,Sa                .SS ."S    .AA,     NN,    .N  .OO'    OOo               .SA`            //
//                SA,               SS,      .AA,A,    NNNN.  .N  OO        OO             .SA              //
//                 ,SA.              .SSs    AA..AA,   NN ,Nn .N  OO        OO           .SA`               //
//                   ?Sa,               SS  AAAAAAAA.  NN   NNNN  OO.      .O^         .S#^                 //
//                     ?Sa,        SS,..S' AA      AA. NN    .NN   ?Oo....OO        .SA^                    //
//                       ,SAN.       SS`                              OO^`        .SAN`                     //
//                          SAN,.                                              ..S#=                        //
//                             SANo.               SANO  ART                ..SA#=                          //
//                                ?SANo,.                              ..sA#"!                              //
//                                     SANOSa-...              ...(sAN#"^                                   //
//                                           ?SA""SANOSANOSANO"""S!                                         //
//                                                                                                          //
//                                                                                                          //
//                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SANO is ERC721Creator {
    constructor() ERC721Creator("Sano Art", "SANO") {}
}