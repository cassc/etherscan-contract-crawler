// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Skinner Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//                                            ..,:codkkOO00000000OOOkdol:,..                                            //
//                                       .,cok0XWMMWWNK00OOkkkkkO00KXNWMMWX0kdc,.                                       //
//                                   .,lkKWMWNKkdl:;'....        ....',:ldk0XWMWXko;.                                   //
//                                .:xKWMWKkl;'.                            ..;lx0NMWXkc'                                //
//                             .:xXWWXkl,.                                      .,cxXWMXkc.                             //
//                           'dKWMXxc.                                              .:xKWWXd,                           //
//                         ;kNMWOl.                                                    .cONMNk;                         //
//                       ,kNMNk;.                                                         ,xNMNk;                       //
//                     .dXMNk,                                                              ,xNMNx'                     //
//                    :KMW0:                                                                  ,OWMXl.                   //
//                  .dNMXo.                                                                    .lXMWk.                  //
//                 'OWW0;                                                                        ,OWM0;                 //
//                ;KMWk.                       .';clodxkOOOOkxddolc;'.                 ;kOOc      .xWMX:                //
//               ,KMWx.                   .;ox0XWMMMMMMMMMMMMMMMMMMWNKOdl,.            oWMMx.      .dNMX:               //
//              '0MWk.                .;oOXWMMMWNKOkdollllllllldxk0KNWMMMWKkl,         oWMMx.       .dWMK;              //
//             .kMMO.               ,oKWMMMN0dc;..                 .':lxKWMMMNOl'      oWMMx.        .xWM0'             //
//             lNMK;             .:kNMMWKxc'                            .,lkXMMMNk;    oWMMx.         '0MWd.            //
//            ,KMWo             ;OWMMNk:.                                   .lONMMNk;  oWMMx.          cNMX;            //
//            oWM0'           'kNMMNk;                                         ;kNMMNx,oWMMx.          .kMMx.           //
//           '0MWo           :KMMWO;                                             ;0WMMXKWMMx.           cNMK;           //
//           cNMX;          lXMMNd.                                               .dNMMMMMMx.           ,0MWo           //
//          .xMM0'         lNMMXl                                                   cXMMMMMx.           .kMMk.          //
//          .kMMx.        :XMMNl                                                     :XMMMMx.           .xMMk.          //
//          .kMMx.       .OMMWd.                                                      lNMMMx.           .xMMk.          //
//          .kMMx.       lWMM0'                                                       .kMMMx.            dMMk.          //
//          .kMMx.      .OMMWo                           .......                       .cll'             dMMk.          //
//          .kMMx.      ;XMMX;                   .':loxkO0KKKKK0Okkdoc;,.                                dMMk.          //
//          .kMMx.      lWMM0'               .;okKNMMMMMMMMMMMMMMMMMMMMWX0xl;.                           dMMk.          //
//          .kMMx.      lWMMO.             ,dKWMMMNK0OOOOOOOOOOOOOOOOOKXWMMMWXOo;.                       dMMk.          //
//          .kMMx.      lWMM0'           ;kNMMWKOkkkO0XNWWWWWWWWWNXK0OkkOOO0NWMMWKd;.                    dMMk.          //
//          .kMMx.      cWMMK,         .xNMMNOxk0NMMMMWXKK00000KKXNWMMMMWX0OkkOKWMMNOc.                  dMMk.          //
//          .kMMx.      ;XMMX;        ,0MMW0dkXMMMXOkOOOOOOOOOOOOOOOOkO0XWMMMNOkxOXMMWKl.                dMMk.          //
//          .kMMx.      .OMMWo       '0MMWkdKMMWKkxOKNMMMMMMMMMMMMMMWX0OkkkOXMMMNOdkXMMW0:.              dMMk.          //
//          .kMMx.       lWMM0'     .xWMWOdXMMNkd0WMMWKkdolllloooxk0XWMMMWKOxx0NMMNOdkXMMNk'             dMMk.          //
//          .kMMx.       .OMMWo     ,KMMXdkMMWxdNMMNx;.            ..,lxKWMMWXkdONMMNkd0WMMK;            dMMk.          //
//          .kMMx.        :XMMXc    ;XMMOo0MMXdOMMWo                    .;dKWMMXkd0WMMKdkNMMXc           dMMk.          //
//          .kMMx.         oNMMX:   ;XMM0o0MMNdkMMWx.  .okxc.              .c0WMMKdxXMMNxxNMMX:          dMMk.          //
//          .kMMx.         .oNMMXl. '0MMWdxWMMOoKMMWO:.cNMM0'                .oXMMNkdXMMNxxNMMK;         dMMk.          //
//          .kMMx.           cXMMWk,.lNMMKdOMMW0dONMMWXXWMM0'                  ;0MMWkdXMMXdkWMMk.        dMMk.          //
//          .kMMx.            ,OWMMXd:kWMMKdkWMMXkxk0NWMMMM0'                   ,0MMWxdNMM0o0MMNl        dMMk.          //
//          .kMMx.             .lKMMMXKNMMMXxdKWMMN0kkOKWMM0'                    :XMMXdOMMWxxWMMO.       dMMk.          //
//          .kMMx.               .o0WMMMMMMMWKkxOXWMMMWWMMM0'                    .xMMMkdNMMOdKMMX:       dMMk.          //
//          .kMMx.       .''.      .:xXWMMMMMMMXOkkkO0KNMMM0'                     cNMM0oKMMXdOMMWl       dMMk.          //
//          .kMMx.       dNWNl        .:d0NMMMMMMMWX0OkKWMM0'                     ,KMMKd0MMNdkMMMo       dMMk.          //
//          .kMMx.      .xMMM0'          .':ok0XWMMMMMMMMMM0'                     ,KMMXx0MMNdkMMMd       dMMk.          //
//          .kMMx.      .xMMMWd.              ..,;clodx0WMM0'                     :XMM0d0MMXdOMMWl       dMMk.          //
//          .kMMx.      .xMMMMNl                       :NMM0'                     dWMMOdXMM0d0MMNc       dMMk.          //
//          .kMMx.      .xMMMMMXc                      .dOOl.                    ,KMMNdkWMWkdNMM0'       dMMk.          //
//          .kMMx.      .xMMMMMMNo.                                             .OMMWkdXMMKoOMMWo        dMMk.          //
//          .kMMx.      .xMMWKXMMWk'                                           'OWMWOdKMMNdxNMM0'        dMMk.          //
//          .kMMx.      .xMMW0dOWMMKl.                                        :0MMWOdKMMWkdXMMNc         dMMk.          //
//          .kMMx.      .xMMMMKdxXMMWKl.                                    ,xNMMNxdKMMWkdXMMNo         .xMMk.          //
//          .kMMk.      .xMMMMMWOxONMMWKd,                               .;xNMMW0dkNMMXxdXMMNo.         .xMMk.          //
//          .dWM0'      .xMMMNWMMN0xkKWMMNOo;.                        .;o0WMMW0xxXMMW0dkNMMXc           .kMMk.          //
//           :NMX:      .xMMW0x0NMMW0xxOXWMMWXkoc,..            ..':okKWMMWXkxkKWMMXxdKWMW0;            ,KMWo           //
//           '0MWd      .xMMMMXOxkXMMWXOkkOKNMMMMWXKOkxdddddddxO0XNMMMMNKOkkONMMWXkdOWMMXd.             lWMK,           //
//            oWM0'     .xMMMMMMNkxk0NMMMN0kkOkO0XNWMMMMMMMMMMMMWWXK0OOkk0NMMMNOxx0WMMNk,              .OMMx.           //
//            '0MWo     .xMMW0OWMMWKkkkOXWMMWNK0OkOOOkOO0O00OOkOOOkOOKNWMMWXOkkOXWMMNx;                lNMX;            //
//             cNMX:    .xMMWl.;dKWMMWKOkkkOKNWMMMMMWNNXXKXXNNNNWMMMMMNKOkkkOKWMMW0o'                 ,KMWo             //
//             .xWM0'   .dMMWc   .:dKWMMMWKOkOOOOO00KXNNNNNNNNXK00OOOOOkOKNMMMW0d;.                  .kMMO.             //
//              .OMMO.   .;:,.      .,lxKNMMMMWXK00OOOOkkkkkkOOOOO0KXWMMMMWKkl,.                    .xWMK,              //
//               '0MWk.                 .':ox0XNWMMMMMMMMMMMMMMMMMMMWX0kdc,.                       .xWMK;               //
//                'OWWO,                      .';:lodddxkOOkxdddolc:,..                           .kWMK;                //
//                 .kWMK:                                                                        ;0WWO,                 //
//                  .oNMNx.                                                                    .oXMNd.                  //
//                    ;OWMKc.                                                                .:0WWK:                    //
//                     .oXMWO:.                                                             ;OWMXd.                     //
//                       'dXMWOc.                                                        .:ONMNx'                       //
//                         'dXMWKo,                                                    'l0WMXx,                         //
//                           .l0WMNOl'                                              'ckNMW0o'                           //
//                             .;dKWMNOd:.                                      .;oONMWKx;.                             //
//                                .;o0NMWXOdc,.                            .,:okXWMN0d:.                                //
//                                    'cd0XWMWX0kol:;'..............';:coxOXWMWN0xc,.                                   //
//                                        .;ldOKNWMMMNNXK00000000KXNNWMMWNKOxl:'.                                       //
//                                             ..,:coddxxxxxxxxxxxxddoc:,..                                             //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SKINZ is ERC1155Creator {
    constructor() ERC1155Creator("Skinner Editions", "SKINZ") {}
}