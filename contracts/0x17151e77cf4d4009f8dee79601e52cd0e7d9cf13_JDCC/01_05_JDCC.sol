// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: manifestian checks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

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
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                     .,cxOl.                                                //
//                                               ... .cKNXXMO.                                                //
//                                               cKXkOXOdkXK;                                                 //
//                                                ;kNXO0KXO,                                                  //
//                                                 .:kXXKd.                                                   //
//                                                   .:,..                                                    //
//                                             .';clodxkkkkxdlc:,''''.                                        //
//                                       .;cok0KXK0kdoolllloxO0KXXNWNX0xo:,.                                  //
//                                   .:oOXXKkdc;'.            ...,;:lodkKNNKOd:.                              //
//                               .:oOXXko:'.                            .':okNWXx;                            //
//                            .:xXW0o;.              .                       'cOWNx.                          //
//                          'oKWNk:.                :d.                        .lXMK:                         //
//                        'xNMNx,                   lK,                          oWMXc                        //
//                      .lXMWO,                   .'kNkoool'                     .OMMX;                       //
//                     .kWMNd.                .:odxkXWXNMMXc                      oWMMk.                      //
//                    'OWMWx.                   ....xWN0ko.                       ;XMMK,                      //
//                   .kWMMK,                     .cONWd.                          '0MMWc                      //
//                   cNMMMx.                   'oKWNXWx,,,''.                     .kMMWl                      //
//                  .kMMMNc                   ,0WNXKNMNXXXXKO;                     dMMWl                      //
//                  ,KMMMK,                    ','..oNd......                      oMMMo                      //
//                  :NMMMO.                         cNl                            lWMMd                      //
//                  cWMMMx.           .l;           :No                   ,l'      lWMMx...                   //
//                  lWMMMx.    .;.  .cOx.           :No           .'.   .l0l.      lWMMKdol.                  //
//               .;:OMMMMd     .lkdlxO:             :Xl           .lxxlckO;        oMMMNOkd,                  //
//               :k0NMMMMd       'OWWx.             .'.             .:KMWk.       .xMMMO:,'.                  //
//               ;odKMMMMx.     .oOc:k0x;.                          .d0lc0Kl.     .kMMWl                      //
//                  lWMMMk.     cd'   ;dK0o.                       'kx'  .oX0c.   '0MM0,                      //
//                  ;XMMMO.     .       .:c.                      .dl.     ,dk;   ;XMNl                       //
//                  .xWMMXc..                                      .             .xWWd.                       //
//                   .c0WMNKK00Okxdoc;.                                        'l0WMX;                        //
//                     ;XMOc:cllodxOKNXx'                                  .:oONNKXM0'                        //
//                     .OMk.        .;0M0'          .'.  .c'          .'cd0NNKxl,;OMk.                        //
//                      dMX;          ,KMx.         cK:  '0o         .kWN0xc,.   ;XMo                         //
//                      ;XWo   .:clc;. lWN:         ,o.   :;         ;XMx..;lll. :NWl                         //
//                      .xM0'  ,cc:c:. ,KMx.                         :NWo .,;:;. cWNc                         //
//                       ;XWo   .col;. .xMKl;,'......................lNWl .;cc:. oMX:                         //
//                       .xM0'  .''..   ;0XXNWNXXXXXXXXK0KKKKKKXXXXKKNWK;       .xMK,                         //
//                        ;XWo           ...lNk;:ONx:lKXkocxN0c:kWkc0Xo.        '0Mk.                         //
//                        .dMK,             'x:  :d.  co'. .d;  ,k; lk.         lWNc                          //
//                         ,KWx.             .                   .  ..         ;KWx.                          //
//                          cNNc                                              .kM0'                           //
//                          .dWXl.              .:. .            .           .dWX:                            //
//                           .lXWOl'.           ;0l.ll   ;x''c. 'k:          cNWo                             //
//                             .lONN0dc,.       .kk.c0,  oK;:K: .kx.        :KWx.                             //
//                                .:dOXNX0xoc;'..;c..x:  cO''x;  dx.     .,dXWk.                              //
//                                    .,coxOKNNX0kdoll:,';;'.....;:;:clox0NNO:.                               //
//                                          .';codk0XNNNNNNXXKKKKXNNNX0Okdc'                                  //
//                                                 ...'',,;::cccc:;,...                                       //
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
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JDCC is ERC721Creator {
    constructor() ERC721Creator("manifestian checks", "JDCC") {}
}