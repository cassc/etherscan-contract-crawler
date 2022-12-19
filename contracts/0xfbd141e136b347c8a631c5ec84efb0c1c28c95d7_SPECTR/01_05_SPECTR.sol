// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spectre Spirits
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                        ..';:cloddxkkkkkkkkkkxxdolc:;,...                                                                                       //
//                                                                                 .';coxO0KKK0Okxdoolll0WWKolloodxkO0KKK0Oxoc;'.                                                                                 //
//                                                                            .':ox0XNWWXOo:'...        oWMk.        ..',:lok0KX0ko:'.                                                                            //
//                                                                        .,cd0XX0xxKWX0KK0kdc;'.      .dWMk.                ..;cdOKX0xc,.                                                                        //
//                                                                     .:dOXXko:'.;ONO;..,cox0KK0kdl;'..dWMk.                      .;lxKX0d:.                                                                     //
//                                                                  .:xKX0d:'.  .oXXo.       ..,:oxOKK0OKWM0:.                         .;lOXXkc'                                                                  //
//                                                            .. .:dKNOo,.    .,ONO;.              ..,:o0WWNXKOdl:'.                      .'ckXXk:.                                                     .         //
//                                                            .'o0N0o;.      .lXXd.                    .dWW0:;ldOKKKOxl:,.                    'lONKd,.                                                            //
//                                                          .;dXXk:.        ,kN0:.                     .dWMO.   ..':ldOKXKOxl:,.                .,dKXk:.                                                          //
//                                                        .;xXXd;.        .cKNx'                       .oWMO.          .';ldk0KKOxoc,..            'l0NO:.                                                        //
//                                                       ,xXXd'. ..      'xNKc.                        .dWMO.                .';cdk0KK0xoc,..        .l0NO:.                                                      //
//                                                     .dXXd'. .  .    .cKNx'                          .dWMk.                      .';cok0KK0koc;..    .lKNk,.                                                    //
//                                                   .cKNk,.          'dNKc.                           .dWMk.                            ..;cox0KK0kdl;'.'dXXo.                                                   //
//                                                  'kNKc.          .:0Nk,                             .dWMk.                                  ..,cox0KX0kxONW0:.                                                 //
//                                                .:KNx.           .dXXl.                              .dWMk.                                        ..;cox0NWWXo.               ..                               //
//                                               .oNXc.          .;0NO,.                                oWMk.                                              ;KNO0Nk'                                               //
//                                              .xN0;           .oXXo.                              ..;o0WMO.                                              ,KNc'kW0;.   .                                         //
//                                             'kWO'          .;ONO;.                            .;lkKX0KWMk.                                              ,KNc .xNK;.                                       .    //
//                                            .OWk.          .oXXd.                          .;lkKX0dc'.dWMk.                                              ,KNc  .dNK:.                                           //
//                                           .kWk.         .,kN0:.                       .;lkKX0xc,.    oWMk.                                              ,KNc   .dWK;                                      .    //
//                                          .dWO'         .lKNd.                     .,lxKX0xc,.        oWMk.                                              ;KNc    .xWO,                                          //
//                                          lNK;         'xN0:.                  .,lxKX0xc,.            oWMO.                                              ;KNc     'OWx.                                         //
//                                         ;KNl        .cKNx'               ..,lxKX0xc,.                oWMk.                                              ;KNc      :KNl.                               .        //
//                                        .xWx.       .xNKc.            ..;lxKX0xc,.                    oWMk.                                              ;KNc      .oW0,                                        //
//                                        cNX;       :0Nk'           .;lxKXKxl,.                        oWMk.                                              ,KNc     . '0Wd.                              ...      //
//                                       .kWx.     .dNKl.        .,lxKXKxl;.                            oWMk.                                              ,KNc       .lNK;                              ..  .    //
//                                       ;XX;     ;0Nk,      .,lxKXKxl;..                               oWMk.                                              ,KNc      . ,0Wo.                                 .    //
//                                       oWO.   .oXXl.   .,lx0XKxl;..                                   oWMk.                                              ,KNc        .dWO.                                      //
//                                      .OWo   ,ONO, .,cx0XKxl;..                                       oWMk.                                              ,KNc         cNK;                                      //
//                                      ;KNc .lXXx:cx0XKxl;.                   ....                    .dWMO.                                              ,KNc         ,KNc                                 .    //
//                                   .lkKNN0xONWXKXKxl,.                    .ck00K0x:.               .lOXWWN0o,                                            ,KNc         'OWo.                          .    ..    //
//                                  ,0Nk:;;oKWWXOd:'.......................,ONOc;;l0Nx'.............:KNx:;,;dXXl.                                          ;KNc         .kWd.                  ..       ... ..    //
//                                 .dWk.    cNWNK00000000000000000000000000XW0,    ;XWK0000000000000XWx.     lW0'                                          ;KNc         .kWx.             .    ........ ......    //
//                                  lNK:. .'xWKl::::::::::::::cccccccc::cc:dXXl.  .dNKo:::::::::::::kW0:.  .,kWk.                                          ;KNc         .kWx.      .      ... ................    //
//                                  .c0X0kOKXNXl.                          .:OXKOOKXk,              .lKX0kkOXKd.                                           ,KNc         .OWd.      ..      .  .   ..       ...    //
//                                    .,dXNd':0Nk'                           .,clc:'.                 .;OWWKc.                                             ,KNc         '0Wl.             .      ...       ...    //
//                                      '0Wl  .dNKc.                                                    oWMk.                                              ,KNc         :XX:                         ....         //
//                                      .xWx.   :0Nx'                                                   oWMO.                                              ,KNc        .oW0,    ...       .......   ......        //
//                                       cNK,    .xNK:.                                                 oWMk.                                              ,KNc        .kWx.    .... .   ........         ....    //
//                                       '0Wl     .:KNx.                                                oWMk.                                              ;KNc        :XXc       ....   ...  ........     ...    //
//                                       .oW0'      'xN0:.                                              oWMk.                                              ,KNc       .xWk.      ..   ..   .  ........   ....     //
//                                        '0Wo.      .cKNd.                                            .oWMk.                                              ,KNc       :XXc            ...    ...........          //
//                                         lNK;        'kN0;                                            oWMk.                                              ,KN:      'OWx.      ..      .     ... ........        //
//                                         .kWk.        .lXXo.                                          oWMk.                                              ,KNc     .oW0,       ..      ....   ..   .......       //
//                                          ,0Nd.         ,ONO,                                        .oWMk.                                              ,KN:     cNX:            .   .....  ..   ......        //
//                                           :XNl.         .oXXl.                                       oWMk.                                              ,KN:    :KNo.                   ...  .   .   ..        //
//                                            cXXl.          ;ONk,                                      oWMk.                                              ,KN:   ;KNd.         ..         ........               //
//                                             cXXl.          .dXXl.                                    oWMk.                                              ,KN:  ;KNd.          ..        ...........   .         //
//                                              :KNo.           :0Nk'                                   oWMk.                                              ,KN: cKNo.                        .......    .         //
//                                               ;0Nx.           .dNKc.                                 oWMk.                                              ,KNooNXl.               ...    .       ..              //
//                                                'kN0;           .:KNx'                                oWMk.                                           ..;dXNXN0;                  . ........    .      ...      //
//                                                 .lXXo.           'xNK:.                              oWMk.                                     ..;cdk0KKKNWNx.                    .. ........ ... .. .... .    //
//                                                   ,ON0:.          .cKNd.                             oWMk.                              ..';ldk0KKOxo:;cON0:.                      ...................... .    //
//    . ..                                            .lKNx,           'kN0;                            oWMk.                         .';ldOKKKOxl:,..  .oXXd.                          ................ .....    //
//    ....                                              'dXXd'          .lKXd.                          oWMk.                   .';ldOKKKOdl:,.       .lKNk,                             .....................    //
//    ....                                                ,dXXd,          ,kNO;                         oWMk.            ..,:lxOKKKOdl:'.           .lKNk;.                             ......................    //
//    . ..                                                  ,dXXx;.        .lXXo.                       oWMk.      ..,:oxOKK0kdl;'.               ,dKXk;.                                .....................    //
//    ....                                                    'o0NOl'        ;ONO,                      oWMk...,:oxOKK0kdc;'.                  .:kXKd,                                    ....................    //
//    .                                                         .:xXXkc.      .oXXl.                  .'kWWXOOKK0kdc;'.                     .;dKXOc.                                       ...................    //
//    .       ..                                                   'lkXXkl,.    ;0Nk'           ..;cok0KNWWXxc;'.                        .:xKXOo,                                           ..................    //
//    ..  ......                                                     .'ckKXOd:'. .dNKc.   .';cok0KK0xoc;kWMk.                        .;lkXXOl,.                                              .................    //
//    ..........                                                         .:oOXXOdc:oKNkldk0KKOxo:,..    oWMk. .                 .':okKX0dc'                                                   ................    //
//    .........                                                             .':okKXKXWWWXkl;.           oWMk.            ..';cdkKXKko:'.                                                       ..............     //
//          ...                                                                  .,:ldOKKK0kxolc:;,''..'xWMO,..'',;;:lodk0KKKOxo:,.                                                             ..........        //
//                                                                                     .';:loxkO0KKKKKKKXWWNKKKKKKK0Okxolc;'.                                                                      ......         //
//                                                                                             ....'',,,,,,,,,'''...                                                                               .....          //
//                                                                                                                                                                                                 .....  ....    //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SPECTR is ERC1155Creator {
    constructor() ERC1155Creator("Spectre Spirits", "SPECTR") {}
}