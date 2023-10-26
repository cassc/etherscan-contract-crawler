// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NEXT REBEL
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                           //
//                                                                                                           //
//                                                                               ..  ./`                     //
//                                                                          ..wuuuuuuXi                      //
//                                                           `         ..duuuuuuuuuuuuuG.                    //
//                                                         .!    ` ...wuuuuuuuuuuuuuuuuuu&                   //
//        `  `  `  `  `  `  `  `  `  `  `  `  `  `  `   .uuuuA&-....zuuuuuuuuuuuuuuuzuuuuun.  `  `  `  `     //
//                                                    .wuuuuzuuuGzzuuuuuuuzuzZ777zuzuzuzuuuI-.               //
//                                                 .Jwuuuuuzuuzuzuuuzuzuw7=!      ?7uuuuzuuX_`               //
//                                               .(wuuzuuzuuuzuuuzuuuzZ^     .JG.  .zuuzuuzu; `              //
//       `                                      (zwuuuuzuuzuuuzuuuzuu=    .+-.uZ^   (uzuuuuuX+               //
//          `  `  `  `  `  `  `  `  `  `  `   .1wuuuuzuuzuuzuuuzuuC!   ..uuu}.'      (uuzuuzuun.  `  `       //
//                     ..("7!_?"i,           .JuuuuzuuuuuzuuzuZ=!   ..duuuuz)         .uuzuuzuuG-            //
//                  .(4.77(.(,   j  ...   .wuuuuzuuuzuzuuuz7!   .(u,.OuZ^ .Xr ,        .uOuuuzuul       `    //
//       `       .,=,^ .jYdX,.t  j  K(,,.wuuuuzuuzuuuu=?`    .JuuC^   `    .I u<         .wuuuuuI            //
//             .(i?`..Z?N.?= .P   h.;JMN#kuuzuuuuuzuC`    .w+uZ=              uul        .uzuzuzC            //
//            ,i7 .JWH/^ ..Y7    ..,<RudQSuuuzuzC7!`   .&  ?un.  .JX,         Ouun.     .uuuzuI`             //
//          .=,`.+,U; ..Y^      .?u?( (NSuuzuZ7!       juG. (uG.zuZ=           C=`   .duuzuuXuZ              //
//         ,gM;   =^.dMg...     ..ggMN-Huuuu'   .un(-.  (uX, .XX.                   JuuuuzZ>Iwu              //
//         ]7MMN- .dMMM#"`  ..MMMMMM">TmuzuG     1uGjuo. .Xu, .OX,             ...(wuzuzZ<-_jju_             //
//          7,MMMMMMM"   .+MMMMMdMD% . (HHSu)     (uX-1uG..Ou,  Ou,       ..JuuuuuuuuuzZ><   .z_             //
//           .(UMMM3  ..MMMNMM#1P` (. } JkuuGuu,   ?uu, ?wuouu>  C7     .duuuuuuzuzuuZ!<!{    u}             //
//          ...HJ#' .J##MM#MMeXJY=7QHfk HkuzuuuX,   (zu,  _Cn1Z}    ..duuuuuuzuuuzuZX:` `                    //
//          DMTMT .JM#4uMMF@JM,    (Ndd`w#uuzuuuu,   .uu>       ..JwuuuzuuzuuzuzZCu}jl.                      //
//           ?^?iJJ<MiqMMMNJMaF    .8!j!d.uuuzuuuu>   .uZ>    .JuuuzuzuuzuuzuXOC!.u\(}                       //
//                  f MMMMMNk,`       X:J;.zuuzuzuu{      ..wuuuuuuuzuuuzwZOIz!   zr.r                       //
//                 .^-MMNMdNWM#      .W.V] (uuuzuuul,ZnJuuuuuuuzuzuuuzXXZv=<_     uI.r                       //
//                 [.MdMdM[Jydh...(-@d#!P  .juuuuzuuXXuuuuuuzuuuzuzXwvzO<!!       ?{.I.                      //
//                ,.M5MMP(b((dM^.MMF(#O %   (zuzuuzuuuuuuzuuzuuzuuwXZO/! .          .I                       //
//               ,.MF.NMN+M,U4N#W#MN#Mg.i    juuzuuuuuzuuzuuuzuXwZ<?``               X                       //
//              /.MM`dMMMm.M,(g..MMMg#bMNJ.  _?juZZXuzuuzuzzZrC?!                                            //
//            .G4MM'.MMMM""MMP?TNadMb4.,MN]    (z;!(zOOOXuv! .                     ...+wuw+...  .            //
//          .d=.MM!.MdMM!   ,d, (._4#]DL$WW<(.  ?\ _<?!`((.wuuzuXwu&++wuuuuuuwwwuuuuuuuuuuuuuuuuuuu;         //
//        .YJ  d@,.qNMMM. J,(JN(+u..M@d(MoTrjt.      ..,(J.`,uuuuzuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuun..       //
//       f , ..@,.4MMMMM' MMNJ@rLWj7!..yz% JNh,,J7.?7 tdM#uuuuzdMRKuuXgmzudM#T"HHHMMXMMMMMMMM#uqNNuuu2       //
//      -[.!. X.1^M#?=    JMM]S ?~P.#Y76.  .DdNj\   R mMMKuuuzu~MkNXzXM#zuIMKwzuuuuuw..    d#u> MMud#        //
//      ((].\.ih'JF    ... .WMN .Y <...7m. -J .(] .MN&NMMRuzuuu_MXdNuXJ#uzrMRuuuuzuuuuuuuz(#uuuuuuu\         //
//      .q`(.].^.MoM@""MJMMm.4MN-] ..,4HdMMMMM#.MMMMM@"MMXuuzuz:MklWKu-#uu)MWMMMMuzuzuuzuXMXmuuzuuuI         //
//       ..Jb]F dMM"7`  .W""@W#WA#...(uKdf,dH"",MMM^   MNuuzuuu_MSuJMkj#uu\MXuuuzuuuuzuuuuXM#uuuzuzI         //
//        ]JMK! MMhf7u..JQ  (d#qM#,MMNMKdK_5   ,.D     MMuzuuzu_MuuXMHzNuz:MuuzuuzuuzuuzuwjM#uuzuuuX&+       //
//        j.MM, MMM7'  .$Mm.Nhn=?NJMMMM#dtLj          dKuuuuzuz(Mzuud#ZMuu+Muuuzuuzuuuzuur.M#uuuuuuXQ\       //
//         3JMN MMF.MMMM]MMMMMp.MMMNMMMkX#l.+.        dNMNXuuuuzuuuuuuuuuuzuuzuuuuuzuuuzun(HBuzuzuz=_        //
//          1(M[MMNJ.TWMN.MMMMjMM@MN4XggM4c .%        ,"4MMNNgMMMMMMMMMMMMMMMMMMNNmXuuQgggNNgggm77`          //
//         ( -,F(MMMMMN&.,3JBdMMMMgM~NM"YMt,  ,,.....    .TMMM""^`           ??""HHH"""""""""""`             //
//         (/74r1MMMM"""""T"BQ.,TNM#.m. .@] .J^   .MM]                                                       //
//           ~`..dH"?THHMQg...  7NaN(.MMN,,(=<<<j+(MM#                                                       //
//          ..dMMMa,       dMMMMH.MMQMMMMN,    dMMMM@5..                                                     //
//          MMMN .jMN,   .J"     .7#    (TMm. -MMMMMMNa.7(.                                                  //
//        .JMMMM"JMMM#  .MMMMMN, /.\..JgNNNMN.JMMxTMMMMMN, 7(.                                               //
//      ,uMMMM^ dMMMMN.dN, .dMMM  (MMMMMMMMMMNMMMMb.MMMMMMN,"?i.                                             //
//                                                                                                           //
//                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NRBL is ERC721Creator {
    constructor() ERC721Creator("NEXT REBEL", "NRBL") {}
}