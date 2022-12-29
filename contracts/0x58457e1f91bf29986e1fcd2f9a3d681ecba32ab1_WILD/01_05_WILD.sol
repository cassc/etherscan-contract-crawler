// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wild Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//                                            ;               //
//                                            ED.             //
//                                            E#Wi            //
//                         t              i   E###G.          //
//                ;        Ej            LE   E#fD#W;         //
//              .DL        E#,          L#E   E#t t##L        //
//      f.     :K#L     LWLE#t         G#W.   E#t  .E#K,      //
//      EW:   ;W##L   .E#f E#t        D#K.    E#t    j##f     //
//      E#t  t#KE#L  ,W#;  E#t       E#K.     E#t    :E#K:    //
//      E#t f#D.L#L t#K:   E#t     .E#E.      E#t   t##L      //
//      E#jG#f  L#LL#G     E#t    .K#E        E#t .D#W;       //
//      E###;   L###j      E#t   .K#D         E#tiW#G.        //
//      E#K:    L#W;       E#t  .W#G          E#K##i          //
//      EG      LE.        E#t :W##########Wt E##D.           //
//      ;       ;@         ,;. :,,,,,,,,,,,,,.E#t             //
//                                            L:              //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract WILD is ERC1155Creator {
    constructor() ERC1155Creator("Wild Editions", "WILD") {}
}