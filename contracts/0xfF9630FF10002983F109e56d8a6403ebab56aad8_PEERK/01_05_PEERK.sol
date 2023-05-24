// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Peer Kriesel
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                      .:lc:;;;,'''.....         ...';:::.                                       //
//                                                     .kWMMWXXXXXXXXKK000OOOOOOO00KKXK0xd;                                       //
//                       .okxddooolllc::;,,'''........',oKWMKdclllooddxkkOOO00OOkkxdolc;'........'',;:cccdOO:                     //
//                       ;XMWXXNMMWNWWWMMWWWNNNNNNNNNNNNXNMMMWNNNNWNNNNNNNNNNNNNNNNNNNNNNNNXXXXNNNWWMMMMMMMMx.                    //
//                       cNMXc.dWXl'',,;::ccllllloollllloloOWNxllodxKWMMXxlcccccccclcco0WMMXxooddddddddxKWMMx.                    //
//                       ;XMK; oWO.                        :NX;     .,lkKKOdc,.        .:OWNk'          cXWMx.                    //
//                       ,KMK,.xMx.   ;do,                 ;XN:         .;lx0XKx:.       .lXMXo.        ;0NMx.                    //
//                       ,KMK,.ONc   .OMWNk,               ,KWl           .,dXMW0'         'xNWO;       :0NMx.                    //
//                       '0M0''00'   ,KNddXXl. ;oc.        ,KWl      ..;ok0XKko:.            ;0WNd.     :XWMd                     //
//                       .kMK,,Kx.   cNO' ;0Nd.cXWk.       oWK; .;:lx0KKko:'.                 .oXMKc.   :NMWl                     //
//                        dMK,'0o    dWd.  .kNk'lNWx.     .OMXOOKK0Oo:'.                        'xNWO:  :NMN:                     //
//                        lWX; ,'   .kNc    .xNk:kMWl     .ckkoc,..      ';::;,.                  ;OWNk;lNMK,                     //
//                        :NN:      ,K0'     .xNkdXM0'                 'kNNK0KXKOo;.               .:0WNXWMK,                     //
//                        ;XWc      lNx.      .kW00WWc                .xM0;....;oONKd'               .dKWMMK,                     //
//                 .lOx,  ;XWo     .kN:        '0NXNMx.               ;KNc        ,dXXx,               .dWMKl:;.                  //
//                  cNMx. ,KMd     ,KO'         :XWWMK,               oWO'          .dNXo.       .:c;.  oWMKxKWl                  //
//             .cdl..OM0' '0Md.    lNd           lNMMWo              .kMd.            ,OWO'     .OWWW0;.dMM0o0Wl                  //
//             .kMN: dMK; '0Mx.   .kX:           .dWMMK;       .''.  .OWo              .xW0,    lWXoxWO;xMMOoKWc                  //
//              cNMo lWX: '0Mk.   '0O.            '0MMMk.      cXNXd.'0Wl               .dWK,  .kMO.:NOckMMxoXX;                  //
//              ;XMd cWNc '0M0'   cNo             ,KMMMNl      .lXMWo;0Wl              .,oXM0, ,KWo cW0lOMMkdN0'                  //
//              ,KMx.cWWl '0M0'  .dX;            .dWWMMM0'       lXNXkKMo             .xWMMMMk.cNN: lWXk0MM0OWk.                  //
//              '0Mx.:NWl '0M0'  '0O.            lNKkXWWWd.      .,xWWWMd       .,cdkOKWMMMMMWodWK, oWXx0MWO0Md                   //
//              '0Mx.:XWl ,0MO.  lNo           .lNWdlKWNWX:        'OMMMk.   .;dKNKKWMW0dOWMMMNXWO. lW0kXMXx0Wc                   //
//              '0Mx.:NWo '0MO. .xX;        .,ckNMNK0XWMMMk.        :XMMK, 'oKXOoldKN0c. .kMMMMMMx. dMkxWMOoKX;                   //
//              '0Mx.:NWo '0M0' ,Kk.    .;lkKWMNk:,..:KMMMNc         lNMWOxXXd:cdXNk:.   .xMMMMMMx..OWddWMdcXK,                   //
//              '0Md :NWl '0MK, cNo .,lkKK0KWMKc.    ,KMK0N0'        .dWMMXklo0NKd,     .lNNKXMMMd.,KWodMWccNO.                   //
//              '0Md cWWl '0MX; dWOxKNKxodkXXd.     ;0WMk;kWo        .kWMMNXNXx:.      'kNXl.oWMMx.;XWkOMK,cWx.                   //
//              .OMo cWWc '0MNc.ONXNWWK0KXOl.     .oXX0N0':XK;       .cONMMWx.      .,dXNx,  ,KMM0'cWXxOMk.lMd                    //
//              .OMd cWWc '0MWc;Xk'';ccc;'       ,ONk':XK,.dWx.         lNMMNkl;;;cd0NKd,    .OMMXcoW0o0Mx.oMo                    //
//              ,KMd cWWl 'OMWllWd             .oXKc. ,0N: ,0N:         .dWMWWMMNKOko;.      ,0MMWKKMOo0Mx.lMo                    //
//              ,KWl oMWc 'OMWxxWl           .cKNx'   '0Wc  oWO.         .OW0dOWNk:.        'kWXxdxXM0o0Mk.cWo                    //
//              ,KWl .::. .kWWkONc          ;ONO;     .kMo  '0Nl          ;KNc.,okKKOxollodOXNk,  '0MKx0Mk.;Xd                    //
//              '0Wl      .xNMKKX:        ,kN0:.      .xMd.  cN0,          oWK, .cddlodxxxdo:'    '0MN0KMk.'0d                    //
//              .xWx.     'dKMWWX;      ,xXKl.         dMk.  .kWx.         .OMd.;0NXk:.           .kMMWWMk..dl                    //
//               .;'      'o0MMMWl    ;xX0c.           lWO.   ;KNl.         lWX:..;lONKl.          lWMMMMk. ;;                    //
//                        'cOMNXNKo:oOXOc.             cN0'    lNXO:        '0WN00OdodONXd,        .dWMMMk.  .                    //
//                        ':dMKc:0WMXo,                ;XX;.,' .oNM0'        .:oxKWMMNKdo0XOc.      .oXMMk.                       //
//                        ,;oWN: .c0Xk:.               '0WkkWK; .xWWk.    .;ldO0K0kdlc;. .:kXKd,      :XMx.                       //
//                        ,,:NWl   .cOX0o,.            .OMWMNl  .:xKWk;:dOKKkoc,..  ....''';dXWNk;    ,0Mk.                       //
//                        ,,,KMKl'    ,o0X0o:.        .oNMMMOlok0XXWMWWXkl;...;cldkO00KKKKKKKKXNWX;   ,KM0,                       //
//                        ,,'0MMMNx,    .,lkKKOdl:;;:oONKNMMWWMMMWN0xol::ldOKNNX0kdl:,'.........,'    ;XMX;                       //
//                        ;,.OMKdONNk:.     .,:ldkkOkdl;:0Ndlddoc::;:okKWMMMMMWXK00Okd:.              :NMX:                       //
//                        ,,.OMO. ;xXWO:.               lWk.  .:x0KNMWN0kdl:::::cxXMWNk'              :XWN:                       //
//                        ,;.xM0'   'dXW0l.            .OX:    ;ddooc;..     .;oOXKxc'                :0NWc                       //
//                        ,;.xMK,     'oKWKo'          ;XO.               .lkKWMMNkddxxxdddo:.        c0NMo                       //
//                        ,:.dMK,       .l0WXx,        :Nd                .lOO0OOkxdolc::cxNWl      .:kNWWl                       //
//                        ,cc0MXc.....',;;lONWNkl:,,,,;xNk:::::ccccccccc:::cloooooloollllloKMNxlccccxkONWN:                       //
//                         'l0WMNKKKXNWWMMWNXWMMMNKKKKKNWWNNNNWWWMMMMMMMMMMMMMMMMMWWWMMWWWWWWWWWWWWWWWWWMNl                       //
//                           .,;:clooddddddxxxxxkOkdddoooolllllllllllccccc:::::;;;,,,;;,,,,,''''',,,,,,,;,.                       //
//                                                                             ...',;:clloooooolcc:;'                             //
//                                                                    .dOOkkkOO0KXNWWNXKK00OOO00KXNN0,                            //
//                                                                    .:xxddddoolc:;;lolc::;;::ccllc'                             //
//                                                                                  .xWMWWWWWWWWWWNKl.                            //
//                                                                                   .;:peer_k.;,,,;;:;.                          //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PEERK is ERC721Creator {
    constructor() ERC721Creator("Peer Kriesel", "PEERK") {}
}