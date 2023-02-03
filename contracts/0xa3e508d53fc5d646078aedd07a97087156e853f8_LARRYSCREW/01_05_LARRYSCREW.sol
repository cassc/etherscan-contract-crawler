// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Larry's Crew
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOdlc:;,,,;:cldkKWMW0o:'..        ..,cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkl,.               .,lxkd;.                .ckXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMW0l'                       .ckk:.                 'oKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMW0c.                           .:kko,                 .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMNd.                               .o00o.                 :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMXc                                   .:0d.                 ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMX:                                      :0d.                 ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWo                                        lK:                  lWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMM0'                                        .Ok.                 ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMx.                                         dK,                 .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWo                                          lX:                 .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMd                                          oX;                 .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMk.                                        .x0'                 ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMX:                                        ;Ko                 .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMO.                                      .kO'                 oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWk.                                    .x0;                .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWO'                                 .ck0;                .xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMKl.                             .cOXx'               .lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMW0l::::;;,'...               .:kk:.               'oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWNX0Okxdooooooodddddddddl:;..    .;dOx:.             .;lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNOl;'..                ..';:lddxxooxKWMNOoc:;,,''',;cldOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMM0:                              .':lxKNMMMMMMMWWWWWWNNXK00KKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMK;                                    .,cx0NMMMMNOoc;'........',:cokXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMk.                                        .,lk0d,                   .cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMM0,                                                                    .c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWO'                                                                     .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMXd;..  .......'''''..                                                   cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMW0oddddddddddddx0NXOxxdc,.                                                :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMW0c.   .....     :Ok;. .;lxxdl;.                                             :XMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMKl.              :Ko.       .,ldkxo;.                                          oWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMNx.               .xO.            .xWKxxdc'.                                     .kMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMW0:                 '0d              '0k'.:oxkko'                                   ;KMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMWx.                  ;Xo               oX:    oWMd                                    oWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMNo.                   ;Xo               '0x.   cWMx.                                   ,KMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMXc                     ,Kd                lK:   :NMk.                                   .dMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMXc                      .kO.               .kO'  ;XM0'                                    :NMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMXc                        lX:                ,0x. ;XMK,                                    '0MMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMNo                         .OO.                ,Ok':XMWc                                    .xMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MWx.                          ;Kd.                .xO0WMMk.                                    lWMMMMMMMMMMMMMMMMMMMMMMM    //
//    M0'             ;c.            cKo.                 ,xXWMO'                                    ;XMMMMMMMMMMMMMMMMMMMMMMM    //
//    Nc             ;KX;             c0d.                  .:dkxdol:,...                            ,KMMMMMMMMMMMMMMMMMMMMMMM    //
//    O.             dMN:              ,OO,                     .,;codddddddolc:;'.                  '0MMMMMMMMMMMMMMMMMMMMMMM    //
//    l             '0MWc               .o0d.                           ..';::cldddxd:.              .OMMMMMMMMMMMMMMMMMMMMMMM    //
//    '             :NMWl                 ,xOl.                                    .:xO:.            .kMMMMMMMMMMMMMMMMMMMMMMM    //
//    .             oMMMo                   ,xOd,                                     c0o.           .kMMMMMMMMMMMMMMMMMMMMMMM    //
//                 .xMMMd                     'lkxl'                                   lX:           .kMMMMMMMMMMMMMMMMMMMMMMM    //
//                 .kMMMd                       .,okxo;.                               ;Xo           .kMMMMMMMMMMMMMMMMMMMMMMM    //
//                 .kMMMx.                          'cdxxo;.                           lXc           .OMMMMMMMMMMMMMMMMMMMMMMM    //
//                 .OMMMk.                             .:0WX0xl;..                    :0d.           '0MMMMMMMMMMMMMMMMMMMMMMM    //
//                 '0MMM0'                              .xMMMMMWN0Okoc;,..        ..:xOc.            ;XMMMMMMMMMMMMMMMMMMMMMMM    //
//    '            :XMMMX;                               dMMMMMMMMMKocoddddddddddddxd:.              cNMMMMMMMMMMMMMMMMMMMMMMM    //
//    x.          'OMMMMNc                               lWMMMMMMMMK,     ..'''''..                  dMMMMMMMMMMMMMMMMMMMMMMMM    //
//    W0c.     .'oKMMMMMMd                               :XMMMMMMMMX:                               .OMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMXOkxxk0NMMMMMMMM0'                              '0MMMMMMMMWl                               :XMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNc                              .kMMMMMMMMMd                               dMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMO.                             .xMMMMMMMMMk.                             ,KMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWl                              oWMMMMMMMMK,                            .dWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMK;                             cWMMMMMMMMX:                            :XMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMO'                            :NMMMMMMMMWl                           ;KMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMO'                           ;XMMMMMMMMWo                          ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMM0,                          ;XMMMMMMMMWc                         'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMK;                         ;XMMMMMMMMN:                        .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMK;                        :NMMMMMMMMX;                        oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMO.                       :NMMMMMMMMK,                       cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWl                       lWMMMMMMMMK,                      ,0WWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMk.                      dMNNMMMMMM0'                     .kOoKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMk.                     .kMOxNMMMMMO.                     oK;.xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMx.                     '0Wo,0MMMMMk.                    ;0o  ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWl                      :NX:.xMMMMMx.                   .xO'   oWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMK,                     .dMO. lWMMMMd                    :Kl    .kMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWx.                     ,0Wo  ,KMMMWo                   .kO.     ,KMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMX;                      lWK;  .kMMMWc                   :Kl       cXMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWd.                     .OMx.   oWMMN:                   d0,        oNMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMK,                      cNX;    :NMMN:                  .Ox.        .xWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWo                      .OMx.    ,KMMX;                  ,Ko          .kMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMM0'                      lNX;     .OMMK,                  :Xc           '0MMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMNc                      '0Wd.     .xMM0'                  cX:            ,KMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWx.                      oWK,       oMMO.                  cX:             ;KMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMK,                      ;XWl        lWMk.                  :Xl              :XMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNc                      .kMk.        cNMk.                  '0d               cXMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWx.                      lNX:         :NMO.                  .kk.               cXMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMM0'                      ,0Wd.         ;XM0'                   lK;                cXMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMX:                      .xW0'          ,KMX;                   ,0o                 :KMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNo                       cNNc           ,KMN:                    d0'                 ;0MMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWx.                      '0Wx.           ,KMWl                    ;Ko                  'kWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWk.                      .dW0,            '0MMd.                   .x0'                  .xNMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWO'                       :NNl             '0MMk.                    ;Ko                   .lXMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMO'                       '0Wx.             '0MMK,                     d0,                    :KMMMMMMMMMM    //
//    MMMMMMMMMMMMMM0'                       .dWK,              ,KMMN:                     ,0d                     ,0WMMMMMMMM    //
//    MMMMMMMMMMMMM0,                        cNNc               ,KMMWo                      oK;                     .kWMMMMMMM    //
//    MMMMMMMMMMMM0,                        ;KWd.               ,KMMMk.                     '0x.                     .dNMMMMMM    //
//    MMMMMMMMMMMK;                        .OWk.                ;XMMM0,                      lK:                      .oNMMMMM    //
//    MMMMMMMMMMK;                        .xW0,                 :NMMMNc                      .Ok.                       lXMMMM    //
//    MMMMMMMMMX:                        .oNX:                  cWMMMMd                       cK:                        :XMMM    //
//    MMMMMMMMNc                         cNNc                   lWMMMMO.                      .Ok.                        :KMM    //
//    MMMMMMMNl                         :XWo.                   dMMMMMX:                       cK:                         :KM    //
//    MMMMMMWd.                        ;KWd.                   .kMMMMMMd                       .OO.                         :X    //
//    MMMMMWk.                        ;KWx.                    'OMMMMMM0'                       lN0,                         :    //
//    MMMMM0'                        ;KWx.                     ;KMMMMMMWl                       ,0MXl.                       .    //
//    MMMMX:                        ;KWx.                      cNMMMMMMMk.                       dMMWk,                           //
//    MMMWo                        :XMX;                       dMMMMMMMMN:                       ;XMMMXl.                         //
//    MMM0'                      .lXMM0'                      .OMMMMMMMMMk.                      .kMMMMWO:                   ;    //
//    MMMO.                     .xNMMMk.                      :NMMMMMMMMMNc                       oWMMMMMNk;                :K    //
//    MMMK;                    ;0WMMMMd.                     .dMMMMMMMMMMMO.                      lWMMMMMMMNk:.          .;kNM    //
//    MMMWk.                 .oXMMMMMMx.                     ,0MMMMMMMMMMMWd.                    .kMMMMMMMMMMWKxl;,'',:lxKWMMM    //
//    MMMMWO,               ;OWMMMMMMMK;                     dWMMMMMMMMMMMMNl                   .dWMMMMMMMMMMMMMMMWWWWMMMMMMMM    //
//    MMMMMMNx:.         .:kNMMMMMMMMMMO'                   cXMMMMMMMMMMMMMMNd.                'kNMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMWXkdlcccldkXWMMMMMMMMMMMMMKc.               .dNMMMMMMMMMMMMMMMMWKl'           .,dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOl'          .;dXMMMMMMMMMMMMMMMMMMMMMNOdc;,',,:lx0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXxc'.. ..,lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LARRYSCREW is ERC1155Creator {
    constructor() ERC1155Creator("Larry's Crew", "LARRYSCREW") {}
}