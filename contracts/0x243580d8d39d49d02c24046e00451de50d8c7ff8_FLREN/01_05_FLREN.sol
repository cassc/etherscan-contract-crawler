// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Florenaux
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//    ,                                                             //
//         Et                                                       //
//         E#t                                  ,;L.                //
//         E##t           i  j.               f#i EW:        ,ft    //
//         E#W#t         LE  EW,            .E#t  E##;       t#E    //
//         E#tfL.       L#E  E##j          i#W,   E###t      t#E    //
//         E#t         G#W.  E###D.       L#D.    E#fE#f     t#E    //
//      ,ffW#Dffj.    D#K.   E#jG#W;    :K#Wfff;  E#t D#G    t#E    //
//       ;LW#ELLLf.  E#K.    E#t t##f   i##WLLLLt E#t  f#E.  t#E    //
//         E#t     .E#E.     E#t  :K#E:  .E#L     E#t   t#K: t#E    //
//         E#t    .K#E       E#KDDDD###i   f#E:   E#t    ;#W,t#E    //
//         E#t   .K#D        E#f,t#Wi,,,    ,WW;  E#t     :K#D#E    //
//         E#t  .W#G         E#t  ;#W:       .D#; E#t      .E##E    //
//         E#t :W##########WtDWi   ,KK:        tt ..         G#E    //
//         ;#t :,,,,,,,,,,,,,.                                fE    //
//          :;                                                 ,    //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract FLREN is ERC1155Creator {
    constructor() ERC1155Creator("Florenaux", "FLREN") {}
}