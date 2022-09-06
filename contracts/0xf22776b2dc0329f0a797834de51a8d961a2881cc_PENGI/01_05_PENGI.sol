// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pengitats
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                       .                                        //
//                                                                     .;cloodddddxxxxxk00l.                                      //
//                                                                     c00OkkxxKMNkddooool,                ......                 //
//            .;clc:.   .,clllcclll:.           .;.       ';:,.     .c:...    .oW0'              'loodxxkOO0KKX0:  .,;;,.         //
//         ,dOXXK0KNKc .oNN0O000OOOd.  ,oc.    .OWo    .:OXXXN0:    lW0,      .dMO.         ,oc. ,xkxONMKdlc:;,'.:kXXKKXKl        //
//        lNXx:'. .xW0'.OMx.          .kMNl    cNX:   .xNKl'.cx:   .kMk.      .kMx.        :XMWx.    ,KWo      .oNXo'..';.        //
//       .kMk.    .xWO''OWd.          ,KMMO'  .kWk.  .kW0,         ,KWl       .OWd        ;KWNWX:    ;XNc      .OMk.              //
//       .kMk.   'dNX: '0Wx....       cNMMWd. :XNc  .dW0,         .lNX;       ,KWl       'OWkcOWx.   cNX:       cXNx'             //
//       .xMO;,ckXXk,  ,0MNKKKx.      dWKONX:.xWO.  :XNc  ,ddl:' .'xMO.       :XN:      .xWK:'xWNk'  lNK;        ,xXXo.           //
//       .xMNXXKkl,    ;XWkccc,      .xMk,dW0xKWl  .dMO.  ,dkXWNc,cOMd.       cNK;      lNMNKKNWMK;  oWK,          :KWd.          //
//       .xMKl,.       :NX:          .OMx.'0WWM0,  .xMO'   .:0W0,;xKWl       .kW0'     ;KW0dl::OM0' .xM0'    .     .xMO.          //
//       .dWO.         lWK,          '0Wo  cXMWx.   ,0NOoox0NKo. ;k00;       ,KMO.    .OWk.   .dWK,  ,l;    l0Odc;:dXNo           //
//       .dW0'         dWXo:ccloodxk:cXNc  .dNX:     .cxOkxl;.    ...         ;o,     cNK;     .;,          .cdOKKK0k:.           //
//       .dWO.         lXNXKK0Okxxdl;oN0'   .,,                                       .:,                       ....              //
//        'c,           ',...        .;.                                                                                          //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                          .;llllllllllllllllllllllllllllllllllc'                                                //
//                                          .cxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                      .:c,     ,c:.  ,lc.     .;loolc,.     ,l:.         'clllllllc.  ,lllllllllc.                              //
//                      'OMK,   ,KWk. .dMNc   .oKN0xxkXNO:   .xMX:         oWMXOOOOOk;  cOOOXMWKOOx,                              //
//                       :XWx. .xWK;  .dMNc  .xWNo.   'OWXc  .xMX:         oWWo.....       .xMNc                                  //
//                       .dWNc :XWo   .dWNc  ;XMk.     :XMk. .xMX:         oWMXOOOOk;      .xMN:                                  //
//                        'OMO:kWO.   .dWNc  ;XMO.     :NMk. .xMX:         oWWkc::::.      .xMNc                                  //
//                         :XNKNX;    .dMNc  .dWNx'  .;0WK;  .xMNl......   oWWd......      .xMNc                                  //
//                         .dNWNo.    .dWX:   .cONX0O0XXx,   .xWWNKKKKK0:  oWWNKKKKKKc     .dWX:                                  //
//                          .,;,.      .;,.     .':cc:;.      .;;;;;;;;,.  .;;;;;;;;;.      .;,.                                  //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                  ..,;,'.      .'''''''.           .'.    .'''''''''.      .',;,'.    .''''''''''.    .';;;,.                   //
//                'd0XK0KX0d,    cXNX000KKO;        .dNK;  .kWNXKKKKKKk'   ,xKXKKXX0l.  :0XXXNNNXXKl  .oKX0O0XKx'                 //
//               :KW0:...:OWX:   lWWd...:KMO.       .xMX;  .OMXc.......   cXWO;..'oKXo. ..''dWWk,'..  lNWk'..;dd;                 //
//              .OMX;     ;KMO.  lWWOlccxXKc        .kMX;  .OMNkoooooc.  '0M0,     ...      cNWo      ;0WNOxoc;.                  //
//              '0M0'     '0M0,  lWWKxddkXKo.   .   .xMX;  .OMNOxxxxxo.  ,KMO.              cNWd       .:lxk0NWXo.                //
//              .dWNo.   .oNWx.  lWWl   .dWWl  l0k' .kMX;  .OMK;         .xWNo.   'oko.     cNWd     .;ol.  .;0MX;                //
//               .dXNOdloONXd.   lWW0dodkXW0;  :KWOokNWk.  .OMW0xxkkkkd'  .dXN0doxKWK:      cNWd      cKWKdookNNx.                //
//                 'cdxkxdc'     'oooooool:.    'ldxxo:.   .:oooooooool.    'coxxxo:.       'lo,       .:odxxdl,.                 //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PENGI is ERC721Creator {
    constructor() ERC721Creator("Pengitats", "PENGI") {}
}