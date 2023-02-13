// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Metagaming
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                           .:x0XNNXKOdlc;'.                                                                                                   //
//                                          ;OWMMNKKNWMMMMWNKOxol:'..                                                                                           //
//                                         :KMMXd'...,:ldk0XNWMMMWNX0kdlc;..                                                                                    //
//                                        'OMMNl          ..';coxOKXWMMMMWNKOxoc;,'..                                                                           //
//                                 ...  ..oNMMO'. . .. ..  .......';codkKNWMMMMMWWNX0Odoc;'............                        .. .                             //
//                       .:okO00000000000KNMMMNK00000000000000000000000KKNWMMMMMMMMMMMMMMWNKK000000000000000000000000000000000000000Oko:.                       //
//                     .c0WMMWWWNWWWNNNNNNNNNNWWNNNNNNWWWNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNWWMMW0c.                     //
//                     lNMMKo;,''''''''''''''''''''''''''''''',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,''''''''''''''''''''''''''''''',;oKMMNl                     //
//                    ,0MMK;                                                                                                          ;KMM0,                    //
//                    :NMMk.                                                                                                          .kMMN:                    //
//                    cNMMx.    ;xOOd'   ,c:'                                                                                         .kMMN:                    //
//                    cNMMk.   ;KMMMWO' '0MWXo.                                                                                       .xMMWOc;'.                //
//                    cNMMx.   ,KMMMMK: '0MMMk.                                                                                       .xMMMMMWNX0kdl:,..        //
//                    cNMMx.    cXMMO;.:ONMMK:                                                                                        .xMMW0kOKNWMMMMWX0d;.     //
//                    cNMMx.     ,kNO,oWMWXx'                                                                                         .xMMNc  .';codOKNMMWk'    //
//                    cNMMx.       ,l:lkxc'                                                                                           .xMMNc         .,xNMMO    //
//                    cNMMx.                                                                                                          .xMMNc           'OMMN    //
//                    cNMMx.                                                 'cooooc,                                                 .xMMNc           ,0MMX    //
//                    cNMMx.                                               ,xNWWNNWWNk,                                               .xMMNc           lNMWk    //
//                    cNMMx.                                         .,,;lkXMWOl;;lONMNkl:,,.                                         .xMMNc          '0MMX;    //
//                    cNMMx.                                    .;dkOKNWWWK0K0l,'',cOK0KWWWNXOkx:.                                    .xMMNc          oWMWd.    //
//                    cNMMx.                                  ..lNMN000xkd.';;;.  .;;;'.dkx000NMNo..                                  .xMMNc         ,KMMK;     //
//                    cNMMx.                              .,lk0XWMMNd;;'':;l,.... ...'c;:'';,dNMMWX0ko;.                              .xMMNc        .dWMWd.     //
//                    cNMMx.                           ..cONMMN0kdolc:,'. .,l:;.  .;:l;. .',;clodk0XWMWOc..                           .xMMNc        ;KMM0,      //
//                    cNMMx.                        .cx0XWMW0l'.           .od;.  .;dd.           .'l0WMWN0xc.                        .xMMNc       .xWMWo       //
//                    cNMMx.                      'dXWMWK00o. ..          .cd:,.  .,:ol.          .. .l00KWMMXd'                      .xMMNc       :XMM0'       //
//                    cNMMx.                  .;oxXMMMNk:lc. .l,         .:c:lo'  'ol:c:.         ,l. .cl:kNMMMXko:.                  .xMMNc      .kMMNl        //
//                    cNMMx.                 'OWMMMMMW0:;l;'.;l.          ....,,,',,.....         .l;.';l;:0WMMMMMWO,                 .xMMNc      :XMMO.        //
//                    cNMMx.                 oWMM0olox: 'c,'.'c.                                  .c,.',c' :xdloOWMWd.                .xMMNc     .kMMNc         //
//                    cNMMx.                'OMMXo. 'c. .::...:,              .,cc;.              ,c...;:' .c, .lXMM0,                .xMMNc     cNMMk.         //
//                    cNMMx.               :0WNk,   ,c. ':c;''.               ,0WWK;               .'';c:' .c,   ,kNMK:               .xMMNc    .OMMX:          //
//                    cNMMx.             .lXMKl.    .c;  .,;;.            .;.  .,;'  .;.            .;;,.  ;c.    .cKWNo.             .xMMNc    lNMWk.          //
//                    cNMMx.            .oNWk;.      .;:'. .l;            :l.        .l:            ;l. .':;.      .,kWNd.            .xMMNc   '0MMX:           //
//                    cNMMk.           .oNWx,..        .,;,;,.            .l;        ;l.            .,;,;;.        ..,dNWd.           .kMMNc   oWMWx.           //
//                    cNMMk.           lNWd''.                             .c;  .,. ;c.                             .''dNNo.          .kMMNc  ,0MMK;            //
//                    cNMMk.          :XWk.''                                ,. 'c'.,.                               ''.xWNc          .kMMNc .dWMWd.            //
//                    cNMMk.         '0M0,.,.           ..                      ,o'                     ..           .,.'OM0,         .kMMNc ,KMMK,             //
//                    cNMMk.        .xWNc ''         ..,:ccllolc:'.  ..         'l'        .'. .':cloolcc:,..         ', :XWk.        .kMMNc.dWMWo              //
//                    cNMMk.       .xWMk..;.      .;:cx0XWWNNXNWWNKx:',;.       .'.      .;,':xKNWWNXXNWWX0xc::.      .;..xWWk'       .kMMNl:XMM0'              //
//                    cNMMk.     .c0WMXc.';      .xXNWNOdc;'..',:d0WW0c'.  .'.      .'.  ..c0WWKdc,'..',coONWNXk'      ;'.cKMW0c.     .kMMNxkWMNl               //
//                    cNMMk.    ,OWMWOl:.',      oWWKo'.          .cKMNd.  .c:      ;c.  .oNMXl.           'l0WWo      ,,.:lOWMWO,    .kMMWXNMMO'               //
//                    lWMMk.   .kMMXl.:c..'  .:,'OMX:               ;KMNd.  ':.    .;'  .dNMX:               ;KMO',:.  '. ::.cKMMO.   .kMMMMMMNl                //
//                   .OMMMk.   .oNMN00Xo  .  .OKKWWk.               .kMMK,              ,0MMO.               .xWWKKO'  .  lX0ONMNd.   .kMMMMMMO.                //
//                   lNMMMk.     ,lxXMMk.    .kMMNd.               ,kNMK:                :KMNk,               .oXMMO.    .kWMXxl,     .kMMMMMNc                 //
//                  '0MMMMk.        cXMWx'. .cXMWd.               cXMWO, ..  'okOOko'  .. 'kWMXl.              .oNMXl.  'xNMNl        .kMMMMMk.                 //
//                  oWMMMMk.         ,kNWN0OKWWXo.               lNMWk. .',;dXMWNNWMXd;,'. .xWMNo.              .lKWWKO0XWNk;         .kMMMMX:                  //
//                 ,0MMMMMk.         .:0WMMMMMXd.               '0MMNl   .lNMNk:'';kNMNo.   cNMM0,               .oXMMMMMW0c.         .kMMMWk.                  //
//                .dWMMMMMk.        .xNWXkdx0NWWKkol;.          ;KMMWk,  ;KMKc.     :KMK:  ,xWMMX:          .;lokKWWN0xdkXWWk.        .kMMMX:                   //
//                ,KMMMMMMk.        :XMNo. ..'l0WWWMWKd'    ..:xKWWKo.  ;KWK;        ,0WK:  .lKWWXxc'.    .oKWMWWW0l,.. .oNMNc        .kMMWx.                   //
//               .dWMWWMMMk.        .xWMN0Od:;,;oxlxNMMKxodk0XWWXOc.   ,0MX:          ;KMK;   .ckXWWN0kdodKWMNxcdo;,;:dO0NMWk.        .kMMNc                    //
//               ;KMMK0NMMk.         .cOWMMK:..'.,;.:ONNXXKK0xo:.     .dWWo.           lNWx.     .:ox0KKXXXNO:.;;.'..;KMMW0l.         .kMMNc                    //
//              .xWMWdoNMMk.           .oNMMO.    ,, .',....       'c:lKM0'            .OMXo:c,       ....,'. ,,    .kMMWd.           .kMMNc                    //
//              :XMM0,cNMMk.            .OMMNl ..  '.             .xNWWMMx.             dWMWWWk.             .'  .. cNMM0'            .kMMNc                    //
//             .xMMNl.cNMMk.             cNMMO. ,'                 .:0MMM0;.          .;0MMM0:.                 ', .kMMNl             .kMMNc                    //
//             :XMMO. cNMMk.             .dWMWd..:,                 .lNMMMN0Okd:,,:dkO0NMMMNo.                 ':..oNMWx.             .kMMNc                    //
//            .kMMNc  cNMMk.              .xWMNo..:;               .,:dXMMWX0XWWWNWWX0XWMMNd:;.               ,:..oNMWk.              .kMMNc                    //
//            cNMMk.  cNMMk.               .dNMWx'.,:'              .;:cll:..'OMMMMO,..:lll:;.              .:,.'xNMWx.               .kMMNc                    //
//           .OMMX:   cNMMk.                .cXMWKl..,;,.             ...     'oxxo'     ...             .,;,..lKWMXl.                .xMMNc                    //
//           lNMMk.   cNMMx.                  'kNMW0l'..'..                                            ..'...l0WMNk,                  .xMMNc                    //
//          '0MMX:    cNMMx.                    ;kNMMXxc,..                     .,.                    ..,cxXWMNk;.                   .xMMNc                    //
//          oWMWx.    cNMMx.                      ,kWMMKc'.                     ,:.                    ..c0MMWk,                      .xMMNc                    //
//         ,0MMK;     cNMMx.                       ;XMMK:...                    ...                   ...;KMMX:                       .xMMNc                    //
//        .dWMWd.     cNMMx.                       .oNMMXxl:'            ..            ..            ':lxXMMNd.                       .xMMNc                    //
//        ,KMMK,      cNMMx.                        .:OWMMWX0kdl:,.    .''''.        .''''.    .,:ldk0XWMMW0c.                        .xMMNc                    //
//       .dWMWo       cNMMx.                          .;okKNWMMO,.       ..            ..       .,kMMWNKko;.                          .xMMNc                    //
//       ;XMM0'       cNMMx.                              .,OMM0,   ..':kKXx'        .xKKk:'..   ,OMMO;.                              .xMMNc                    //
//      .xWMNl        cNMMx.                                ,0WMXxl;;:dXMMMWk.  .'. .xWMMMXd:;;lxXWM0;                                .xMMNc                    //
//      :XMMO'        cNMMx.                                 .o0WMMWNNWMMMMKd:...,..:oKMMMMWNNWMMWKo.                                 .xMMNc                    //
//     .kMMNl         cNMMx.                                   .;ldkOkxloKMKc''.  ..'cKMXdldkOkxl;.                                   .xMMNc                    //
//     cNMMO.         cNMMx.                                             ;KMNd.    .oNMX:                                             .xMMNc                    //
//    .OMMXc          cNMMx.                                             .dWMX:    ;KMMx.                                             .xMMNc                    //
//    lNMMk.          cNMMx.                                              ,0MWKdlld0WM0,                                              .xMMNc                    //
//    0MMX:           cNMMx.                                               'dKNWMMWWKd'                                               .xMMNc                    //
//    XMM0'           cNMMx.                                                 .';::;,.                                                 .xMMNc                    //
//    KMMX:           cNMMx.                                                                                                          .xMMNc                    //
//    lXMMXxl;'..     cNMMk.                                                                                         .;ll;.    ..     .xMMNc                    //
//     ;kNWMMWNX0kdl:;dNMMx.                                                                                        .kWMMWx. .dXXk:   .xMMNc                    //
//       ':oxOKNWMMMMWWMMMx.                                                                                        ,KMMMMNc .OMMM0'  .xMMNc                    //
//            ..,:ldk0NMMMx.                                                                                        .oNMMXd'.lXMMWd.  .xMMNc                    //
//                   .oNMMx.                                                                                         .lKWO';0WMMXo.   .xMMNc                    //
//                    cNMMk.                                                                                           'lkldXXOl'     .kMMNc                    //
//                    ;XMMO.                                                                                              ..'.        .OMMX:                    //
//                    .kMMNd.                                                                                                        .dNMWk.                    //
//                     'OWMWKkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkKWMWO'                     //
//                      .cOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOc.                      //
//                         .,:ccccccccccccccccccccccccccccccccccccccccldk0XNWMMMMMMMMMMWX0kxolccccccccccccccccccccl0MMM0lccccccccccc:,.                         //
//                                                                       ..';coxO0KXWMMMMWNKOxoc:,..              '0MMX:                                        //
//                                                                                ..,:ldk0XNWMMMWWX0kdlc;..      .kWMWd.                                        //
//                                                                                        .';coxOKXWMMMMWNKOxolldKWMWx.                                         //
//                                                                                               ..,:ldk0XNWMMMMMMNOc.                                          //
//                                                                                                      .':oOKXNXkc.                                            //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SLVRMG is ERC1155Creator {
    constructor() ERC1155Creator("Metagaming", "SLVRMG") {}
}