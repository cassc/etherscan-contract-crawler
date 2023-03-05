// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Art of Zachary Mojica
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                   .'..                                                                     //
//                                .;;;:dx,                                                                    //
//                              .cc.  .lXO.       .,..dOOd.     ,lc'                                          //
//                              ;0d;cdKWMWl       ,0c,0MMNl   ;kNMM0,                                         //
//                              ;XNNWMMMMMk.     'do,dNMWMNOkONMMMK;                                          //
//                              ;XOxNMMWMMK,   'lo:cOWMMMMMMMMMMMWl      ..                                   //
//                              ;XxoXMMMMMNc .ld;:kNMMMMMMMMMMMMMMXl'..:xKx'.                                 //
//                              ,KxlXMMMMWO',dc.cKMMMMMMMMMMMMMMMMMWNXXWNxcl'                                 //
//                              ;XdcXMMMMO,;d,.lXMMMMMMMMMWXOxdddx0NMMMMk:kc                                  //
//                              cNocXMMMWc,o, cNMMMMMWKdllclolc:cc::oKWMdcO:                                  //
//                              lNocNMMM0,:c .kMMMMNOc':lodoc,..';oo:,d0o,dc                                  //
//                              dNllNMMMO.cl  cXWXk;'cxdl;.  .'','';ooc;;cd,                                  //
//                              dXclWMMMX:'dl..':::lxd,   ,oOXNWWNXOdddddo'                                   //
//                              dX:cWMMMM0,.cdollll;. .cdkNMMMMMMMMMMNOc.                                     //
//                             .dX;cNMMMMMXc..,,'',:lxKWMMWNXNMMMMMMMMMW0c.                                   //
//                             .dK,cWMMMMNx,;kKXXNWWMMMMMMWO:,lONMMMMMMMMWO;                                  //
//                             .x0':NMMMKc,oXMMMMMWXXXNWMMMWXd..:OWMMMMMMMMXo.                                //
//                             .k0';XMM0;,OWMMMW0o:::c:ccokXMWK:..lKWMMMMMMMWO,                               //
//                             '0O':NM0,;0MMMMXo,:kKNXKkxo:;o0WNx. .oXMMMMMMMMXc                              //
//                             ,Kx.oWK;,0WMMMK:,xNMMWXOkxxxo;,oXWO,  'xNWMMWXOkkl.                            //
//                             ;0c.OX:'kWMMMK;'OWWNkc::clcc;;,.cXMXc.  ;0WKl.   ;c.                           //
//                             :0;.Od.cNMMMK;.dWWO:,oOOOOKNKc...kMMNd.  .o:     co.                           //
//                             :0; '..dK0Ox; .cdl.:0klloollkO; .lK00Ol.   .',;:c;.                            //
//                             ;Kl   .'..         .::xNWWNOll:. .....      ..'.                               //
//                             ,0o                  ,oddddol,.                                                //
//                         .:o:;Ol           .      ,kKNNNKx'     ..    ..      .dl.                          //
//                       'o00d::Oc   ...oxook0x,  .,xWMMMMMXc   ;kKXkdodOKOx,   :OOkc.                        //
//                      '0Xkoo;:0c  ,k0kKMMMMMMXc..;OMMMMMMWx.  .dNMMMMMMMM0'   ;OOdxx;                       //
//                      .cxdc. ,0l  oWMMMMMMMMMNl..oNMMMMMMMK:,l:;oXMMMMMMMk. ...'oxdko.                      //
//                          .lxxKd  cNMMMMMMMMMNOccKMMMMMMMMWOdKWNXWMMMMMMNc  .,.  .''                        //
//                        .lKNKkKd  .kWMMMMMMMMMWNNWMMMMMMMMMWWMMMMMMMMMMWx.  ':.,d:.                         //
//                        ;K0oO0Kk.  ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'   ,c.'kXO;                        //
//                        .lxxo:OX:   ;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.   ,: .:kXl                        //
//                          .. .dWd. ..;KMMMMMMMMXxoxKNWWWWN0k0NMMMMMMMMMk. '.;:  .;,.                        //
//                              cNO. ld.oWMMMMMMMK;  .,,;,,'.,dNMMMMMMMMWo .:,:,                              //
//                              '0X; c0;,0MMMMMMMMNx:'....;oONMMMMMMMMMMK; ;:':.                              //
//                               lXx.,0d.xMMMMMMMMMMWNXXXNWMMMMMMMMMMMMMk..c;;;                               //
//                                :0x'ok'cNMMMMMMMMMMMMMMMMMMMWMMMMMMMMWo .,cl.                               //
//                                 'kx:l,;KMMWXXNXK00OO0KOdolc::o0WMMMMX: .cx,                                //
//                                  .dk; .OMMO,.',.....,;,'.';:c:;xWMMM0'.ox,                                 //
//                                   .lx;.oWMNOxkOOOO00KKXNNNWMMWXXWMMNo'll.                                  //
//                                     ,oloXMMMMMWKxkOl;;:clldXMMMMMMWOcc,                                    //
//                                      .:kNMMMMMWOlc:,,,,;:lxXMMMMMW0dc.                                     //
//                                        .;xXWMMMMMWWNNNWWMMMMMMMWNOc.                                       //
//                                           .:d0WMMMMMMMMMMMMMWNOl'.                                         //
//                                              .;oOKXNNNNX0Oxoc'                                             //
//                                                  ..'''...                                                  //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract THA is ERC721Creator {
    constructor() ERC721Creator("Art of Zachary Mojica", "THA") {}
}