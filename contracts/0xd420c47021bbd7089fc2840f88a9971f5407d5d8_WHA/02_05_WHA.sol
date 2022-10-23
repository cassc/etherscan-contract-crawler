// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WhiteHash Art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                             ,odo:.       ...                                                               //
//                               .,;o00l.     ,d;                                                             //
//                                   'xXk,    :k:                                                             //
//                                    .c0O;   o0c                                                             //
//                       .              :0k, .k0;                                                             //
//                      ,o'             .o0d.;Kk.                                                             //
//                      ;d,              'O0cdXd.                                                             //
//                      ck;              .xXk0K:                                                              //
//                     .lk,              .dXKXx.                                                              //
//                     .xo.   .,'        .dXXKc                                                   ..          //
//                     ck:    .c:        .kNNO'                                              .,cdOKc          //
//                    .dd. .  .l:        :KNXl                                           .;okKNXOo:.          //
//                    :k:...  .ll.      .dXNx.                                      .'cdOXN0xl;.              //
//                   'xd;.    .ol.     .oOXKc                                  .':okKXKOo:'.                  //
//                  .lkc.     .ld.    ,dxxXx.                              .,cx0XX0xc,.                       //
//                  :ko.       ,xo;,:od:,kXc                          .':dOXXKxl;.                            //
//                 ;kd'         .;c:;'. :XO,                      .,cd0XXOd:'.                                //
//                'kx,                 .xNo.                  .cdkKNKkl;.                                     //
//               'kO,                  ,0K:               .;oOXWXOo;.                                         //
//               :d,                   lXx.          .:dxOXX0dc,.                                             //
//                                    .xXl.     .':dOXXOkd:'.                                                 //
//                                    ,0K;  .;oOKNXOddxc'.                                                    //
//                                    cXO::o0WN0d:..,0WOl.                                                    //
//                                   .kWNXXOd:'.   ;0WNd,.                                                    //
//                                .:d0WWO:.       :0KXNd,.                                                    //
//                            .,cxXN00NK;       .lXOcxNkl'                                                    //
//                         .;d0NXkl,.cN0'      .oXO, :XKO:                                                    //
//                     .,lkKXOo;.    dWk.     .dXx'  .kXKd.                                                   //
//                  .:d0X0xc'       .kWx.    .dXx.    :KX0:                                                   //
//                 .oxdc,.          .OWd.   .dXk'     .dNXk'                                                  //
//                                  .ONo.  .oXk'       'oOXd.                                                 //
//                                  .ONo.  lX0,          ;0Xd.      .,.                                       //
//                                  .ONo. cK0;            ,0Nx,    .od.                                       //
//                                  .ONl.;00:              'xX0l. .oO:                                        //
//                                  .kNo;kKc                 ;x0Oxkx;                                         //
//                                   oKkOKo.                   ..'.                                           //
//                                   'kOd:.                                                                   //
//                                    ..                                                                      //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WHA is ERC721Creator {
    constructor() ERC721Creator("WhiteHash Art", "WHA") {}
}