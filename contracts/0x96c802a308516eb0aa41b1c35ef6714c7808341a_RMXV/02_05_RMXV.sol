// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Remix Voucher
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                  .;:.                                      //
//                                                            'coxkOOd'        .'.                            //
//                                                          .xNMMKd;.          ,c;'                           //
//                                                         .dWMMWo           .'oxd:                           //
//                                                         'kWMMNc         .,ld0W0'                           //
//                                                ......'..cXWWMW0;...,;...,xk0WWo                            //
//                                           ':oxk0XXKK00x:dXXNMMM0:.;dOl.,xkkNM0,          .;,   ,l'         //
//                                        'lONWMMMMMMMWK0kodKXWMMMWO;c00ocxxxXMNo          'o:. .lKl          //
//                                     .cxKWWNXXNWWMMW0do;.cxXMMMMMNdlddkkddKWMO.        .lx:..:kXd.          //
//                                    ;kOdc;,'..',,:lc'....cxKNMMMNKdcoxkdkOONXc       .lOO;.'dXNx.           //
//                                 .;ol;.              .,::lKX00KNXdloxkOKkdXXl.     .:kKx,':kNNo.            //
//                                'od'            ';'.'ckxc:oclxxko::odokKOKXo.    .ckK0c':d0NKc              //
//                              .o0l.             ....;okd::l:dKXO;'cl;l0KXNx;llclxKWWk:lk0XWO,               //
//                             'OWk.      ..      ........ .''lxd:,:;'lKNWXkldKNXWMWNN00WMMNd.                //
//                            'OWNc  'cdkO00Oxl:'  ','.      ..'::cl:dXWWXxkKWMMMMXxxXMMMMKc.                 //
//                           .xWMK, :0WMWWWMMMMWK: .,c:,'.......,:oOOkOXXOOXMMMMMNOONMMMNk'                   //
//                           oNMM0' .,coookNMMMMNc   ..;c:'';,.,;;xNXkdOK0XWMMMMMWWMMMW0:.         .;lc.      //
//                          '0MMMx.   .cx0KNWMMWO.   ..';,'',,',;,cONNkx0KNMMMMMMMMMMXd.     ...;lxOkl'       //
//                          ;XMMK;    .:dOOOO0kl.   .',;ll;';;.;;',oKN0xONMMMMMMMMMMXd'  .,lx0KXKkc'          //
//                          '0MWd.      .',,'.     .:oddoc,;;,,,''',cxkkxONMMMMMMMMMWNX00XWWNOd:.             //
//                          .kMX:                  .:kNKxoc:::llc:,',:clco0WMMMMMMMMMMMMWX0x:.                //
//                          ,kWO.          .:lc,,:lokXNx:llccd0000O00KXNOodOXMMMMMMMMWKxkKXXKkc.              //
//                         ',;dc           .l0N0OXWNNXOl:cccdXNNWMMMMMMNo..lXWXKNWWXOl:o0WMMMMWx.             //
//                         ......           .';cOWXOxolkK0xlkWMMMMMMMMMk'.'xWWXXWMXdcdKWMMMMMMMN:             //
//                          ..,xk;.             :0d;:lONWXo:xNMMMMMMMMNdlkxcldONMNKKNMMMMMMMMMMX:             //
//                           .oXWKo.        ..';ol,:;.oKOKOkNMMMMMMMMMXlco:,:oONMWMMMMMMMMMMWXk;.             //
//                           .cONNx,      ......::,dxo0NNNKKWMMMMMMWX0xccdkKWMMMMMMMMMMMMMW0l.                //
//                             ,OXx,.           ,;;xNWMMMWNKNMMMMW0Od:l0XXWMMMMMMMMMMMMMMKl.                  //
//                             'xXx,           'oc:ONXXX0KKXXXWMWk:;:cdxxONMMMMMMMMMMMNKX0;                   //
//                             .lko.          'ld,'odooookKOkKWMXo::;:lxKWMMMMMWKOOKKk;.;0Xc                  //
//                             ..''          .:kkclOX0lxNXKXNWNNKo;;lONMMMMMWXOo,.....   :XK;                 //
//                                            ,kK0XNXkkXNNWMMW0l;:o0WMMMWX0dll:,,,'.     .xNd.                //
//                                            .oXXXNKKXXXXNNWKdco0WMMMWWWKxc:;..''.'..    .::.                //
//                                             ;00dOXNMXOOO0XX00KNMMMNKKXNNX0koll;''..'..    ..               //
//                       ':cldo'               .xXKkdk0OdkkkOKNWMWWMMWX0OKNWMMWWNKOxc::c:,.                   //
//              ...';:loONMMMXo.               .dNNOxodXKKOkKNNWMWWMMWOx00ONMMMMMMMWXOxl:c:,.   .'.  .,cod    //
//            .d0KXNWMMMMMMMMXc.               'dXWWWXXWNXXWWMMMWXNMMW0xKKONMMMMMMMMMMMNOo:,;,.  ,lcdKWMWW    //
//            lNMMMMMMMMMMMMMWOc.             .;kWNXXKXNK0kONMMWXKNMMMXKNXOKMMMMMMMMMMMMMXx:;;,. ;OWMMNx:,    //
//            oWMMMMMMMMMMMMMMWXo'.           .lXMXOdxKNXOxkKWMMMWWXOKKO0xxXMMMMMMMMMMMMMMWXd:lod0WMMMO.      //
//         .'c0WMMMMMMMMMMMMMMMWXKkc'.     ..'cKWWNx;cokK0KNWMMMMX0Old0o:lKNX0KWMMMMMMMMMMMMWKKNWNWMMMNxl:    //
//    .':ok0NMMMMMMMMMMMMMMMMMMWWMMN0d;.':loldKWNOxc.:dOKNWM00WMNOddk0d.;0X00KWMMMMMMMMMMMMMMMMMWNWMMMMMMW    //
//    KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKXWWNXNWKx;';''lk0XMMO:dN0dlxKo..lOKXWMMMMMMMMMMMMMMMMMMWNNMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx. .'';lk0XMMNl.;oldX0' ;0WMMMMMMMMMMMMMMMMMMMMWNKNMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.  'dKKXXWMMMXdcxXWMx. 'OMMMMMMMMMMMMMMMMMMMMMXkONMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk. ,dKK0XWMMWXkdccOWWx.  ,OWMMMMMMMMMMMMMMMWMN0x0WMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO,,kNNXNWMMMMNOold0WWXd.  .ckXWMMMMMMMMMMMWWN0OXMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOkXWMMMMMMMMMMMMMMMMMWk,   ,xXWWWMWWWWNNNNWWWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXWMMMMMMMMMMMMMMMMMMWXkod0NNWWWWWNNWNNWWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWOcckNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWd.   ;kNMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWO,    .:0WMMMMMMMMMMMMMWNXNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMKl.    .oXMMMMMMMMMMMMWNX0KWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNo.     ;0WMMMMMMMMMMMWXKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RMXV is ERC721Creator {
    constructor() ERC721Creator("Remix Voucher", "RMXV") {}
}