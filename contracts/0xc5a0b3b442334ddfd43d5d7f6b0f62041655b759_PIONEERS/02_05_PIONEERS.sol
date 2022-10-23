// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PIONEERS Space Program
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                         .'.                                                                //
//                                       ,xKNNx.                           .,lddl'                            //
//                                     .dNMMMMWo   ..........            .cOWMMMMNo.                          //
//                                    .xWMMMMMXxoxO0KXNNNNXK0Oxdl:'. .'cxXMMMMMMMMNl                          //
//                                   .lWMMMMMMMMMMMMMMMMMMMMMMMMMMWKO0NMMMMMMMMMMMMk.                         //
//                           .,coxkO00NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                         //
//                         ;xKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.                         //
//                        ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo                          //
//                         .cdONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'                          //
//                          .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOoxOk;                      //
//                         .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                     //
//                        .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.                     //
//                        ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,                      //
//                        lWMMMMMMMMMMMMMMMMMWNWMMMMMMMMMOOWMMMMMMM0OWMMMMMMXKWMMMMMM0,                       //
//                        dMMMMMMMMMMMMMMMMMWk,;oONMMMMWNl.lONMMMMWo'dXWMMMMOdXMMMMNx.                        //
//                        dMMMMMMMMMMMMMMMMWk.    ,dXWWk:.   ,dKWWO'  .cOWMXlxWMMNx,                          //
//                        lWMMMMMMMMMMMMMMXo.       .;,.       .;;.      ,:'lNMXd,                            //
//                        '0MMMMMMMMMMMWKd'       .;coddddol'       .cool;. oW0,                              //
//                        ;kKOxxk0NMN0d:.       .l0NMMMMMMMM0'      dWMMMWO,oWx.                              //
//                      ,oo,.    .'ld'           .;loolclllc'       .:oOKkc.dkdx.                             //
//                     :k; .,ldl:.            .;llccccclo:.          ,ddclxcox;ko                             //
//                    'kc  .cdc:ldc.         ,0x'      ,oO0,        ;Oc   ;xdk:ok.                            //
//                    :0;  .'    .:;         ;Xd.      .cOM0,      .ko    ;kokodx.                            //
//                    ,O:                     c0x,.  .,xXWMK;      .kk,..;Ok;x0Oc                             //
//                     ok.                     .ldddxk00Okl'        .:oodxo.'OK:                              //
//                     .cxc.      .;,             ......       ....,.       :O;                               //
//                       .:lcccc:cOx.                      ..',clokx:.      dd                                //
//                           .....:d.                    .o0NWNKxxKNWXo.   ;k,                                //
//                                 ;o,                 ;xKMMMMMMMMMMMMX;  .kl                                 //
//                                  .cl,              ;XMMMMMMMWNWMMMMX; .xo.                                 //
//                                    'cl:.          .kMMMMMMWXl,xWMMWd.,xc                                   //
//                                      .;ll:'.      ,KMMMWXkc.  .dNWx;ld,                                    //
//                                         .;cccc;'. .ldol:.       ;ddo:.                                     //
//                                             .':cccccccc:;,,',;:ccl;.                                       //
//                                                   ..',,;:c::;;,.                                           //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PIONEERS is ERC721Creator {
    constructor() ERC721Creator("PIONEERS Space Program", "PIONEERS") {}
}