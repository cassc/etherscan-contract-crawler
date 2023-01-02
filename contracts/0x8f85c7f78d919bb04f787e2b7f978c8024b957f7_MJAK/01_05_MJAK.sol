// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MAJESTIC ARKANUM
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                             ......                                                             //
//                                                        .;ok0KXXXXK0ko:.                                                        //
//                                                      ,dKWWKkdollodkKWWKd,                                                      //
//                                                    .dNMKo,.        .,oKMNd.                                                    //
//                                                   .kWNx.              .xNWk.                                                   //
//                                                  .dWWd.      ....      .dWWd.                                                  //
//                                                  ,KMK,     .l0XX0l.     ,KM0,                                                  //
//                                                  ,KM0'     .OMWWMO.     '0MK,                                                  //
//                                                  .OMNc      .cooc.      :NMO.                                                  //
//                                                   :XMK;                ;KMX:                                                   //
//                                                    cXMXo.            .oXMX:                                                    //
//                                                     'xNMXxl;'....';cxXMNx'                                                     //
//                                                       'lOXWWNXXXXNWWXOl'                                                       //
//                                                          .,clooool:,.                                                          //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                          'oc.                     'o:                                          //
//                                           ;o:.        .ckXMWk'                  .lOd.                                          //
//                                           .oX0dlc:clxONWMMMMMXdc;.           .:xKO;                                            //
//                                             ;kNMMMMMMMMMMMMMMMMMWKOdl:'.';:okXWXo.                                             //
//                                               ;dKWMMMMMMMMMMWXkooxOOXWWNWWMMMWO,                                               //
//                                                 .;lxO0KK0Oxl;.    .cKMMMMMMMXl.                                                //
//                                                      ...         .xNMMMMMMWk'                                                  //
//                                                                .:KMMMMMMMKc.                                                   //
//                                                              'kXWMMMMMMNx.                                                     //
//                                               :oc:;;,,,,;;;;oXMMMMMMMMWk'                                                      //
//                                               oWMMMMWWWWMMMMMMMMMMMMMMMWXOc.                                                   //
//                                               '0MMMMMMMMMMMMMMMMMMMMMMMMMMWk.                                                  //
//                                                'd0NWMMMMMMMMMMMMMMMMMMMMMMMWo                                                  //
//                                                  .';:kWMMMMMMMWNkccccccccloxl.                                                 //
//                                                    .lKMMMMMMMKc..                                                              //
//                                                   ;OWMMMMMMNx.                                                                 //
//                                                 .dNMMMMMMW0;                                                                   //
//                                                :0WMMMMMMXo.    ..',;;;,'.                                                      //
//                                              'kNMMMMMMMNo..,cxO0KNWMMMWNX0x:.                                                  //
//                                            .lXMWX0OkxkKNN00NMMMMMMMMMMMMMMMWXd,                                                //
//                                           ;OKkc,..    .':okXMMMMMMMMMMMWNXXNWMNd.                                              //
//                                          c0d'              'kWMMMMWKko:,'...,cxXO'                                             //
//                                          ..                 .xWWKd;.           'c,                                             //
//                                                              .,,.                                                              //
//                                                                                                                                //
//                                                                                                                                //
//                                                                .....                                                           //
//                                                           .;ox00KK0xoc;'.                                                      //
//                                                         ,xXWMWKkd:'..  .                                                       //
//                                                       .dNMMW0c.                                                                //
//                                                      'OWMMWk.                                                                  //
//                                                     .xWMMMO.                                                                   //
//                                                     ,KMMMWc                                                                    //
//                                                     ;XMMMN:                                                                    //
//                                                     'OMMMWo                                                                    //
//                                                      cNMMMX:                                                                   //
//                                                      .lXMMMXl.                                                                 //
//                                                        ,kNMMWOc,.                                                              //
//                                                          ,o0NWWWXkoc:;,..                                                      //
//                                                             .;clloolc:'.                                                       //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MJAK is ERC1155Creator {
    constructor() ERC1155Creator("MAJESTIC ARKANUM", "MJAK") {}
}