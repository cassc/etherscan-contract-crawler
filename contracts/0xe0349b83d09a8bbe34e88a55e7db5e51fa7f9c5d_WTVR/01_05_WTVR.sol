// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WTVR_TREATS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                      .,:oxO0XNNWWMMMMWWNXKOxl:'.                                                             //
//                                                                  .:dOXNMMMMMMMMMMMMMMMMMMMMMMWN0xc'                                                          //
//                                                               'lOXWMMMMMMWNX0OkkxddddxkO0XNWMMMMMWXkc.                                                       //
//                                                            .cONWMMMMWN0xl:'..           ..,:okXWMMMMWKd'                                                     //
//                                                          'dKWMMMMWKxc'.                       .:xXWMMMMXd.                                                   //
//                                                        'dXWMMMWXx;.                              .l0WMMMWKc.                                                 //
//                                                      .oXMMMMW0l.                                   .lKWMMMNx.                                                //
//                                                     ;0WMMMWKl.                                       'xNMMMWO'                                               //
//                                                   .oXMMMMXo.                                          .oXMMMW0,                                              //
//                                                  .kWMMMWO,                                              cXMMMWO'                                             //
//                                                 ,OWMMMNd.            ....                 .'..           lNMMMWx.                                            //
//                                                ,0WMMMXl.          .ckKXXKOo'           'oOKXX0x:.        .dWMMMNc                                            //
//                                               'OWMMMXc           'kNKo;;ckNXo.        :KNkc,;o0N0;        '0MMMMO'                                           //
//                                              .kWMMMXl           .kW0,     :KNl.      :XNo.    .dN0'        lNMMMNl                                           //
//            ...'''''''.....                  .oWMMMNo.           cNX:       ':.      .kWk.      .;;.        '0MMMMk.              ...,;:clooddddol:'.         //
//        'cdO0XNNNNNNNNNXXK0Okxdol:;'..       :XMMMWx.            :kl.                .ox,                   .xWMMMK,       ..,codk0KNWWMMMMMMMMMMMWNKx:.      //
//     .cONWMMMMMMMMMMMMMMMMMMMMMMMMWNX0kdlc,.,OWMMMK,                                                         lWMMMXc..,:lxOKNWMMMMMMMMMMMMWWWWWWMMMMMMW0:.    //
//    'OWMMMMWX0OkxxxxkkkO0KKXNWWMMMMMMMMMMMWXXWMMMWo                                                          :NMMMWK0XWMMMMMMMMMWWXKOkdolc:;;,;;cokXWMMMNo    //
//    OWMMMNx;..           ...',;cloxO0XWWMMMMMMMMM0'                                                          ;XMMMMMMMMMMMWX0kdl:,..               ,OWMMMN    //
//    WMMMWo                          ..,:ldOXMMMMWo                                                           ,KMMMMWNKOdl:,..                       oWMMMW    //
//    WMMMWo                      .',.      .xWMMMK;                                                           ,KMMMWk,.    .',.                    'oXMMMMK    //
//    0MMMMXx:,'.....            'kNWNx.    '0MMMMk.                                                           ,KMMMWo     :0NWXl.       ...',;:codOXWMMMW0;    //
//    ,0WMMMMWWNXXKK0OOkkxxdooc:cOWMMMK,    ;XMMMWo                                    ..''.                   ;XMMMWo    .dWMMMXl';codkO0KXNWWWMMMMMMMWKo.     //
//     .lONWMMMMMMMMMMMMMMMMMMMMWMMMMNo     cNMMMNc                                  ,d0XXXXOo'     .''.       :XMMMNl     :XMMMWNNWMMMMMMMMMMMMMMWNXOd:.       //
//       .':odxkO00KKXXNNNWWWMMMMMMMWk.     lWMMMX:    .;dxo,                       lXNx;',ckKx.   ,kNNXo.     lNMMMNc     .OMMMMMMMMMWWNXKOkxdolc;,.           //
//                ......'',;:coKMMMMX:      lWMMMX;    cNMMM0,                     ;KWo.     ..   .xWMMM0'     dWMMMK;      oWMMMWKxoc;,...                     //
//                            'OMMMMO.      lWMMMX:    lNMMMX:                     oWK,           ;XMMMWd.    .kMMMM0'      :XMMMWo                             //
//                            :XMMMWo       cNMMMNc    :NMMMNc                     oNk.           oWMMMX:     '0MMMMx.      ,KMMMWd.                            //
//                            lWMMMX:       :XMMMWl    :XMMMWl                     .'.           .kMMMMO.     cNMMMNl       ,KMMMWd.                            //
//                            oWMMMK,       ;KMMMWo    :XMMMWl                                   '0MMMMx.    .xWMMMK,       ;KMMMWd                             //
//                           .dWMMMK,       '0MMMWd.   cNMMMNc                                   ;XMMMWo     ;KMMMWx.       cNMMMNc                             //
//                            oWMMMK;       .lXWWK:    oWMMMX;                                   cNMMMNc    .dWMMMX:       .xWMMMK,                             //
//                            lNMMMX:         .;,.    .OMMMMO.                                   cNMMMNc    .kMMMWx.       ;KMMMWx.                             //
//                            ;XMMMWo                 lNMMMWo                                    :NMMMWl     'okxc.       .kWMMMK;                              //
//                            .OMMMMO.               :KMMMWO'                                    '0MMMMk.                .dWMMMNo.                              //
//                             lNMMMNl              cKMMMMK;                                     .oWMMMNl               .xWMMMWx.                               //
//                             .OWMMMXl.          ,xNMMMMK;                                       .OWMMMXl.            :0WMMMNd.                                //
//                              ,OWMMMNOl,.....;lkNMMMMWk'                                         ,OWMMMNx,        .:kNMMMMXl.                                 //
//                               .xNMMMMWNXKKKXWMMMMMW0c.                                           .xNMMMMNOdllloxOXWMMMMNk,                                   //
//                                 ;xKWMMMMMMMMMMMWKx;.                                              .c0WMMMMMMMMMMMMMMWXk;.                                    //
//                                   .;lxO00K0Okdl;.                                                   .;d0NWWMMMMWNX0xc'                                       //
//                                         ...                                                            ..,:ccc:;'..                                          //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                       ..                                     //
//                                                                                                                 .,coxOKK0d,                                  //
//                                                                                    .,;'.                  .':lx0XWMMMMMMMM0,                                 //
//                                                 .',..                        ..':dOXWWN0:  .lk0Od'   ..:ok0NWMMMMMMMMMMMMMX:                                 //
//                                                :0NWNO:.                  .;lxKXNWMMMMMMMO..kWMMMM0'.o0NWMMMMMMMWX00NMMMMMWx.                                 //
//                                               .kMMMMMNo             .,cdOXWMMMMMMMMMMMWKc ,KMMMMMK,;XMMMMMMWKdc;;o0WMMMMXo.                                  //
//                                                cNMMMMMX:        .;okKNWMMMMMMMMMMWX0xl;.  cNMMMMMk..:ONMMMMWd..l0WMMMMNk,                                    //
//                                                .dWMMMMM0,   .cd0XWMMMMMMMMMMNKOkl;.      .xWMMMMWo   .OMMMMW0kXWMMMMNO:.                                     //
//                              .:x0Ox;            .OWMMMMWk. ;KMMMMMMMMMMMNOdc,...         .OMMMMMN:   .OMMMMMMMMMMMNk:.                                       //
//                             .dNMMMMX;            ;KMMMMMNl.lNMMMMMMMMMMWx. ,dO00kl.      ;KMMMMM0'   '0MMMMMMMMWXx;.                                         //
//                            .oNMMMMMK,             oNMMMMM0'.lOKKXWMMMMMNc ,KMMMMMWx.     lNMMMMMx.  .lXMMMMMMMKo'                                            //
//                            :XMMMMMNl              'OMMMMMNl   ..lNMMMMM0' ;KMMMMMMX:    .xWMMMMWl  :0WMMMMMMMMK:                                             //
//                           'OMMMMMWx.               oWMMMMMk.   .dWMMMMWx. .xWMMMMMWx.   ,0MMMMMK; .dNMMMMMMMMMMNd.                                           //
//                           oWMMMMM0'                ;XMMMMM0'   .OMMMMMNc   ;KMMMMMMNc   oWMMMMWx.  .;kWMMMMMMMMMW0:                                          //
//                          ,0MMMMMNl,cool,.          .OMMMMMK,   ;XMMMMMK,   .dWMMMMMM0, ,KMMMMMX:     cNMMMMWMMMMMMNd.                                        //
//                          oWMMMMMKkXMMMMNO:.        .OMMMMMK,   lNMMMMMk.    'OWMMMMMWOcOWMMMMWx.     lNMMMW0kXMMMMMW0:                                       //
//                         '0MMMMMMWWMMMMMMMNk,       ;KMMMMMO'  .xMMMMMWo      ;xKMMMMMWWWMMMMM0,      oWMMMWd.,kNMMMMMNx'                                     //
//                         cNMMMMMMMMMMMMMMMMMXd'   .;0WMMMMWd.  '0MMMMMX:       .;KMMMMMMMMMMMK:       dWMMMWd. .cKWMMMMWKc.             ...                   //
//                         dWMMMMMMMMMMWWWMMMMMWXkddONMMMMMMK;   :XMMMMM0'         ,OWMMMMMMMMK:        dWMMMWd    .xNMMMMMNk'          ;kKNXk;                 //
//                        .xMMMMMMMMMMWOcoKWMMMMMMMMMMMMMMMXc    lNMMMMMx.          .oXWMMMMNx,         .xXNN0;      :0WMMMMMXl.       .OMMMMM0'                //
//                        .dWMMMMMMMWXo.  .l0WMMMMMMMMMMMWO;     ,OWMMWK;             .cdddc'             .''.        .dNMMMMMWO,      .oNMMMNd.                //
//                         .xNMMMMNKo'      .;d0NWMMMMWXk:.       .;ll:.                                                :0WMMMMMXo.      'clc,                  //
//                           ':llc,.           .':cllc;.                                                                 .dNMMMMMWO,                            //
//                                                                                                                         :0WMMMMMXl.                          //
//                                                                                                                          .dNMMMMMWO,                         //
//                                                                                                                            :KWMMMMMXc.                       //
//                                                                                                                             'xNMMMMMNo.                      //
//                                                                                                                              .cKMMMMMNc                      //
//                                                                                                                                ,OWMMMX:                      //
//                                                                                                                                 'xNWXo.                      //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WTVR is ERC1155Creator {
    constructor() ERC1155Creator("WTVR_TREATS", "WTVR") {}
}