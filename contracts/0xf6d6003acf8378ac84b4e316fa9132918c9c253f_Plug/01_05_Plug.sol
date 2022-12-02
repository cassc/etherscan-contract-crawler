// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: STZ Plug
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                              .,c'            //
//                                       ..                                                                'dxl:'.                       ..,:lxOXXd.            //
//                                      ;0l                                                                 .:OWX0Oxdlc:;,,,,,,,;::cloxk0KNWMMMWO,              //
//                                    .lKO'                                                                   .oKXXNNNNNNNNXXXXNNWWWWWWWWWWNNWNo.               //
//                                  .:OXXd                                                                      lXNWMMWWNNNNNNNNWWWWWWWWMWNNW0;                 //
//                                .:kNWNXc                ..                                                     oNNWMMMMMMMMMMMMMMMMMMMWNWWx.                  //
//                              'lONWMMNX:               ;Od.                                                    .OWNWMMMMMMMMMMMMMMMMMNXWNd.                   //
//             ..           .,ckXWWMMMMNNo            .:xXWd.                                                     lNWNWMMMMMMMMMMMMMMWNNWNl                     //
//            ,O0xlc:;;;:cox0NWWMMMMMMMWWKd,......,:okKNNNNc                                                      '0WNWMMMMMMMMMMMMMWXNMNl                      //
//             ,OXXXWWNWWWWWMMMMMMMMMMMMMWWNK000KXNWWWMMNNK,                                                      .kMNNMMMMMMMMMMMMWXNMXc                       //
//              .oXNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNO.                       ..''''...                      .kMWNWMMMMMMMMMMWNWMX:                        //
//                ;0NXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNk.        .:l'       .:ox0XNNWNNXKOdc'                  .OMWNWMMMMMMMMMWNWMK;                         //
//                 ,0NXWMMMMMMMMMMMMMMNOokNW0oxXWMMMMMMWXNk.        .OM0,       ...':okKWMMMMMMNOc.               :NMWNWMWWWWWMMWNWMX:                          //
//                  ;KNNMMMMMMMMMMMW0l'   ;:.  .:kNMMMMWXNO.        .xMW0'             .;dXMMMMMMWKc.            .OMWNNNNNWWNNWMNNMNc                           //
//                   lNNNMMMWWWMMMMWKxo;.     'ld0NMMMMWXNO. .;d:    oWXXO'               'kWMWNNMMWO,          ;OWWNXNWWNNWNWMWNWWo                            //
//                   .ONNWWXOkKWMMMMMKxc.     ;d0NMMMMMMNN0coKXo.    lWNKXO'               .xWMWXNWMMXd.     'lONMWNXNMNOkXXNWWNNMk.                   ..       //
//                    oNXXk:..xNWMMMX;  .:k0o.  .kMMMMMWNWWWMNo.     oMWNXN0,               ,KMMNNWNWMMXxoox0NMMWNNNWMNxdXWWWWWWMX;                .;ldl.       //
//                    cXk;   .dNWMMMk..:OWMMMXo. cWWWNNNWMMMWd.     .xMMNNNNKl.             '0MMNNWWNWMMMMMMMWWNNWNNMWo'cxdlllo0Wd            .':dOXWNo.        //
//                    ';.    .dNWMMNl;OWMMMMMMMKc;OWWWMMWNWMk.      '0MMNNMNNNO;.           oNMMNNMMWNWMWNNWWWWWMWNWMk.        cO'        .,cx0NMMMMK:          //
//                           .xNWMMN0NMMMMMMMWWMW0KWWWWNXXWX:       cNMWNNMMWNWNOdl,.    .;kNMMWNWMMMWNMWXNMMMMMMNWMX;         ..     .,cxKNWWWNWMWO'           //
//                           'OWMMMMMMMMMMWWNWWWWMMWWWWNNMMx.      '0MMNNWMMMMWNWWMWX0OO0XWMMWWNWMMMMMNWMNNMMMMMWNWMk.            .'cxKWMWNNNNXXWWx.            //
//                           :KWMMMMMWNWWNNWMMMMWNWMMMWNWMNc      ,OMMWNWMMMMMMWWNNNWWWWWWWNNNWMMMMMMMWNMWNWMMMMWNWMd         .,cdkOOxOWMNNMWNNMNo.             //
//                       .,lx0NMMMMMNNWMMMMMNxcdXWNWMMNNMM0'  .;oONMWNNWMMMMWWWMMMMWWWWWWWWWMMMPLUGMMMWNWMNNMMMMWNWMk.     .';cc:,.. ,0WWNWWNWMXc               //
//        ;x;         .:d0NWWWMMMMMWNWNd:xNNl.  :XWNWWNWMMk,:xKWMWWNNWMMMMWNWWNNWWWMMMMMMMPLUGMMMMMMMMWNWMWNWMMMMNNMX;              ;KMWNNWNWMK;                //
//        dM0'     'lkKNWWWMMMMMMMMNNMK,  ''     oWNWWNWMMXXWMWWNNWWMMMMWNNWWNWWNNNWMMMMMMMMMMMMMMMMMMWNNWWNWMMMMWNWMO'           .lXMWNNWNWWO'                 //
//        oWWx. 'lkXWWWMMMMMMMMMMMMNNM0'         '0WWMNNWWWWNNWWMMMMMMMWNWMWx,xWMMWNWMMMMMMMMMMMMMMMPLUGWWWWMMMMMMWNWW0,        .;kWMWNWNNWWx.                  //
//        :NNKOkXWWWMMMMMMMMMMMMMMWNNM0'         .kNNMMWWWWWWMWWWWWWWWWNWMMK; .xWMMWNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWXx;....;d0WMWNNWNNWNd.                   //
//        '0NXWWWWMMMMMMMMMMMMMMMMWNNMO.          dNNMMMMMWWNWNWWWWMMMMMMMM0'  '0MMMNNMMMMPLUGMMMWNNNNWWMMMWWMMMMMMMMWWNWNK0KNWWWNNNWWNNMNl.                    //
//        .kNNMMMMMMMMMMMMMMMMMMMMWXNMk.          oNWMWWNNNWWMWX0Oxddxk0XWMX;   :0NMWNWMMMMMMMMMNN0dkNWNWMWNNNWMMMMMMMMWWWWWWWWWWWMMWNNMXc                      //
//         oNNMMMMMMMMMMSTZMMMMMMMWNNMx.         .xNNNNWWWXko:'..       .;od'   .'xMMWNNWWWWWMMWNXc  cXNNWNXKXNWMMMMMMMMMMMMMMMMMMMMNNMXc                       //
//         lXWMMMSTZMMMMMMMMMMMMWWWWWMo          ,KWNWKkl;.                       'OWMMMWWWWWWWWNNd   dNNNWd;OWNMMMMMMMMMMMMMMMMMMMNNMNc                        //
//         :XWMMMMMMMMMMMMMMMWWNWWWMW0;         .kNOo;.                            .,:cllllllooooo:   :XNNO'.OWNWMMMMMMMMMMMMMMMMMNNMNl                         //
//         ;KWMMMMMMMMMSTZWNNWWWKkl:'.          .;'                                                   ;XW0, :XMWNWMMMMMMMMMMMMMMMWNWWo.                         //
//         ,0WMMMMMMMMMWKKXNKkl,.                                                                     lXd.  dMMMNNWWWWWWMMMMMMMMWNWWx.                          //
//         'ONSTZMMMMWNK0Od;.                                                                        .;,   .OMMMWWWWWWNNWWNWWMMMNNM0'                           //
//         .kWWMMMWNNX0d;.                                                                                 ;XMWX0OOO0XNWMMWWWWWNNWWo                            //
//         .kNWMWNNKx:.                                                                                    :kl,..   ...,:codOXWNWM0'                            //
//         .xNNNN0o'                                                                                                         ,0MMWl                             //
//         .kXXKo.                                                                                                            ,KMk.                             //
//         .OXd.                                                                                                               oK;                              //
//         .c,                                                                                                                 .'                               //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Plug is ERC1155Creator {
    constructor() ERC1155Creator("STZ Plug", "Plug") {}
}