// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Barren Outpost Quest Rewards
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                              .,codkOOOkoc,.                                                                                    //
//                          .,okXWMMMMMMMWKxc.                                                                                    //
//                       .,d0NMMMMMMMMN0o;.     .';:ccc:,..                                                                       //
//                     .cONMMMMMMMMWKd,.    .:okKNWMMMMMWX0xoc,..                                                                 //
//                   .c0WMMMMMMMMW0c.    'ckXWMMMMMMMMMMMMMMMMWX0xdoc,..                                                          //
//                 .:0WMMMMMMMMWOc.   .:kXMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xo:,..                                                    //
//                'xNMMMMMMMMWKc.   .l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xo:,.                                               //
//              .cKMMMMMMMMMNd.   .c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWX0xo:.                                          //
//             .dNMMMMMMMMW0:    ,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOo;.                                          //
//            .kWMMMMMMMMWk'   .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc'     .';clodol:,.                             //
//           'OWMMMMMMMMNd.   ,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl.    .,lk0NWMMMMMMWN0o,                           //
//          .kWMMMMMMMMNo.   :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk;.   .;dKWMMMMMMMMMWXkl,.      .....                 //
//         .xWMMMMMMMMNo.   cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx,    .l0WMMMMMMMMMWXkc.     .:lxO0KXXKOxc'             //
//         lNMMMMMMMMWd.   cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;    'oKWMMMMMMMMMW0l'    .;dOXWMMMMMMMMMMMXd.           //
//        ,0MMMMMMMMMO.   :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKl.   .oXWMMMMMMMMMW0c.   .;dKWMMMMMMMMMMMMMMMMW0;          //
//        oWMMMMMMMMX:   '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,   .c0WMMMMMMMMMW0c.   .cONMMMMMMMMMMMMMMMMMMMMM0,         //
//       .OMMMMMMMMWd.  .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.   'xNMMMMMMMMMMXo.   .c0WMMMMMMMMMMMMMMMMMMMMMMMWx.        //
//       ,KMMMMMMMMX;   ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX0l.   ;0MMMMMMMMMMWO,   .:0WMMMMMMMMMMMMMMMMMMMMMMMMMMX:        //
//       .cxOKNWMMMk.  .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc.    cXMMMMMMMMMMNo.   'xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo        //
//           .,:lxOl.  .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl    .lNMMMMMMMMMMKc    :KWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.       //
//       .'.           .xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.   .lNMMMMMMMMMMK;   .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.       //
//       :KXOxl:'.      ..,cok0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.    cXMMMMMMMMMMK;   .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdc'        //
//       :XMMMMWNKk,          ..;cdkKNWMMMMMMMMMMMMMMMMMMMMMMK;    ,KMMMMMMMMMMK:   .xWMMMMMMMMMMMMMMMMMMMMMMMMWN0xl;.            //
//       :XMMMMMMMNl   'ddl;'.      ..;cdkKNWMMMMMMMMMMMMMMMWd.  .;xWMMMMMMMMMNc   .xWMMMMMMMMMMMMMMMMMMMMMNKko:'.     .,'.       //
//       :XMMMMMMMNl   ;XMMWNx.   ..      .';ldOKNWMMMMMMMMMK;   :0XMMMMMMMMMWx.  .oNMMMMMMMMMMMMMMMMMWXOdc'.     .':okKNO.       //
//       :XMMMMMMMNl   ;XMMMM0'   o0kdc;..      .';ldOKNWMMMk.  .xWWMMMMMMMMM0,   :XMMMMMMMMMMMMMWX0dc,.     ..;lx0NWMMMMO.       //
//       :XMMMMMMMNl   ;XMMMM0'  .dMMMMWX0koc,..      .':lxOc   '0MMMMMMMMMMWo   .kMMMMMMMMMWN0xl;.      .,cx0XWMMMMMMMMMO.       //
//       :XMMMMMMMNl   ;XMMMM0'  .dMMMMMWWWMMWX0d.              .xKXWMMMMMMMK;   :XMMMMMNKko:'.     .,cdOXWMMMMMMMMMMMMMMO.       //
//       :XMMMMMMMNl   ;XMMMM0'  .dMMWKd:;:lOWMMX;   ,doc,.       ..,:ox0XWMk.  .dWWXOdc'.     .':okKNMMMMMMMMMMMMMMMMMMMO.       //
//       :XMMMMMMMNl   ;XMMMM0'  .dMMO'     .dWMX;   cNMMWXO,           ..,c,   .:l,.      .;lx0NWMMMMMMMMMMMMMMMMMMMMMMMO.       //
//       :XMMMMMMMNl   ;XMMMM0'  .dMWd.      cNMX;   cNMMMMNc   'dkxl:'.              .,cd0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.       //
//       :XMMMMMMMNl   ;XMMMM0'  .dMMXl.    ;0WMX;   cNMMMMNc   ;KMMMWNKOdl;.    .'cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.       //
//       :XMMMMMMMNl   ;XMMMM0'  .dMMMNc   ,0MMMX;   cNMMMMNc   ;XMMMMMMMMMWd.  .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.       //
//       :XMMMMMMMNl   ;XMMMMO'  .dMMMNl   ,KMMMX;   cNMMMMNc   ;XMMMMMMMMMMx.  .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.       //
//       :XMMMMMMMNl   ;XMMMM0'  .dMMMNl   ,KMMMX;   cNMMMMNc   ;KMMMMMMMMMMx.  .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.       //
//       :XMMMMMMMNl   ;XMMMM0'  .dMMMW0dddONMMMX;   cNMMMMNc   ;KMMMMMMMMMMx.  .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.       //
//       :XMMMMMMMNl   ;XMMMMO'   ;kKNWMMMMMMMMMX;   cNMMMMNc   ;KMMMMMMMMMMx.  .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.       //
//       :XMMMMMMMNl   ;XMMMM0'     .';ldkKNWMMMX;   cNMMMMNc   ;KMMMMMMMMMMx.  .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.       //
//       :XMMMMMMMNl   ;XMMMMNOoc;..      .';ldOk,   cNMMMMNc   ;KMMMMMMMMMMx.  .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.       //
//       :XMMMMMMMNl   ;XMMMMMMMMWX0koc;..      .    cNMMMMNc   ;KMMMMMMMMMMx.  .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.       //
//       :XMMMMMMMNl   ;XMMMMMMMMMMMMMMWX0koc,..     cNMMMMNc   ;KMMMMMMMMMMx.  .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.       //
//       :XMMMMMMMNl   ;XMMMMMMMMMMMMMMMMMMMMWX0xoc,.oNMMMMNc   ;KMMMMMMMMMMx.  .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.       //
//       'xKNWMMMMNl   ;XMMMMMMMMMMMMMMMMMMMMMMMMMMWXNWMMMMNc   ;KMMMMMMMMMMx.  .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.       //
//         .':ldOXXc   ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc   ;KMMMMMMMMMMx.  .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.       //
//               .'.   ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc   ;KMMMMMMMMMMx.  .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.       //
//                      ,cok0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc   ;KMMMMMMMMMMx.  .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKo.       //
//                          ..;ldOKNWMMMMMMMMMMMMMMMMMMMMMMNc   ;KMMMMMMMMMMx.  .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdc,.         //
//                                .':lxOXNMMMMMMMMMMMMMMMMMNc   ;KMMMMMMMMMMx.  .kMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xl;.              //
//                                      .,:ox0XWMMMMMMMMMMMNc   ;KMMMMMMMMMMx.  .kMMMMMMMMMMMMMMMMMMMMMMWN0xl;..                  //
//                                            .,cok0XWMMMMMNc   ;KMMMMMMMMMMx.  .kMMMMMMMMMMMMMMMMMMNKko:'.                       //
//                                                 ..;cdkKNNc   ;KMMMMMMMMMMx.  .kMMMMMMMMMMMMMWXOdc,.                            //
//                                                       .';.   ;KMMMMMMMMMMx.  .kMMMMMMMMWN0xl;.                                 //
//                                                              .;cox0XWMMMMx.  .kMMMMNKko;..                                     //
//                                                                   ..,cok0o.  .xKOo:'.                                          //
//                                                                         ..    ..                                               //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OUTPOST is ERC1155Creator {
    constructor() ERC1155Creator() {}
}