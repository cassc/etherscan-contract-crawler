// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Burn Olympics
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                              ..''''..                      .''''''..                     ..''''..                              //
//                          .:ok000OOO00Odc'              ,lxO00OOOO000kl;.             .:dO00OOOO00Od:.                          //
//                        ,dKKxc,......':o0Kk;.        .cOXOl;'.......;lkK0o.         ,xK0d:,......':d0Kx;                        //
//                      .oX0c.            .;kXk'      ;0Xd,              .oKKc.     .xXO:.            .:OXx.                      //
//                     .kNd.                 cXK;    lX0;                  'kNd.   'OXo.                .lX0,                     //
//                    .dNd.                   :X0'  :X0,                    .ONl  .kNl                    lNO.                    //
//                    ;X0'                    .xWd..kWl                      :N0,.lNO.                    .kNc                    //
//                    :Nk.                  'cdKMN00NW0o:.                .;lOWWKOXMXxc,.                  dMo                    //
//                    ;X0'               .lOKOxKMk,;0M0x0Kk:.          .;xK0xOWKc'dWXkkK0o'               .kWc                    //
//                    .kNl             .lKKo' ;KK,  cNO..;xX0:        ,OXk:..xWo  .ONc..l0Xd.             :X0'                    //
//                     ,0Xl           .kNx.  ,0Xc   .dNk.  ,ONd.     lX0;  .dNk.   ;KK:  .oX0,           :KX:                     //
//                      'kXk,        .kNo. .oXK:     .lXKc. .kNo    cN0' .:OXd.     ,OXx'  cX0'        'dX0;                      //
//                       .:OXOl,.    cN0c:xKKo.        'xK0d;lXK,  .ONd;o0Xk,        .c0Xkc:OWo    .'ckX0l.                       //
//                          ,ok00OkxxKMNKOd:.            .cx0KWW0xxOWWX0kl'            .;oO0NMXkxkO00Oo;.                         //
//                             .';:ccOMO'                   .;0WkccdNXc.                   .xW0lc:;,.                             //
//                                   ;X0'                    :X0'  .kNl                    .kNl                                   //
//                                   .oNk.                  ,0Xc    ;KX:                  .dNx.                                   //
//                                    .oX0:               .lKK:      ,0Xd.               ,OXx.                                    //
//                                      ,kXOc'         .,o0Xx'        .oKKd;.         .:kXO:                                      //
//                                        ,oOK0xolcclok0KOl'            .ckK0kdllcloxOK0d;.                                       //
//                                           .;loddddoc;.                  .,clddddol:'.                                          //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OLYMP is ERC1155Creator {
    constructor() ERC1155Creator("Burn Olympics", "OLYMP") {}
}