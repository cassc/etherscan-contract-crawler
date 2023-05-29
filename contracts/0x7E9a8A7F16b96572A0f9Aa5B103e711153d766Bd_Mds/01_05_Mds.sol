// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Meds
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//                                                             //
//                                     ;                       //
//                                     ED.                     //
//                                   ,;E#Wi               .    //
//                                 f#i E###G.            ;W    //
//                ..       :     .E#t  E#fD#W;          f#E    //
//               ,W,     .Et    i#W,   E#t t##L       .E#f     //
//              t##,    ,W#t   L#D.    E#t  .E#K,    iWW;      //
//             L###,   j###t :K#Wfff;  E#t    j##f  L##Lffi    //
//           .E#j##,  G#fE#t i##WLLLLt E#t    :E#K:tLLG##L     //
//          ;WW; ##,:K#i E#t  .E#L     E#t   t##L    ,W#i      //
//         j#E.  ##f#W,  E#t    f#E:   E#t .D#W;    j#E.       //
//       .D#L    ###K:   E#t     ,WW;  E#tiW#G.   .D#j         //
//      :K#t     ##D.    E#t      .D#; E#K##i    ,WK,          //
//      ...      #G      ..         tt E##D.     EG.           //
//               j                     E#t       ,             //
//                                     L:                      //
//                                                             //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract Mds is ERC1155Creator {
    constructor() ERC1155Creator("Meds", "Mds") {}
}