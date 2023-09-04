// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Igor Jacobe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                            .:::;,''..        ,KMMMMMN: cO'                              '0MMMMMMM0'                                            '0MMMMMO.                                    .OMMMMMMMK,  ;X    //
//                            .ccccloddxxo:.    ;XMMMMMN: cO'                              '0MMMMMMM0'                                            '0MMMMMk.                                    .OMMMMMMMK,  ;X    //
//                                     .':c.    ;XMMMMMN: cO'                              .OMMMMMMM0'                                            '0MMMMMk.                                    '0MMMMMMMK,  :N    //
//                                              ;XMMMMMX; cO.                              .OMMMMMMMO.                                            '0MMMMMx.                                    '0MMMMMMMK,  :N    //
//           .;ooddooool:;'.                    :NMMMMMX: lk.                              .kMMMMMMMO.                                            '0MMMMMx.                                    '0MMMMMMM0'  :N    //
//            .',:codk0KNWNX0kdoc:;,'..         :NMMMMMX; lk.                              .kMMMMMMMO.                                            '0MMMMMx.                                    '0MMMMMMM0'  :N    //
//                     ..:xKWMMMMMMWWX0kdol:,.  :NMMMMMX; lk.                              .xMMMMMMMO.                                            '0MMMMMd                                     '0MMMMMMM0'  :N    //
//                        .;:clllooddxxxkkO0OoclkWMMMMMX; lk.                              .xMMMMMMMk.                                            '0MMMMMd                                     ,0MMMMMMM0'  :N    //
//                                      ..',,. ,OMMMMMMX; ox.                               dMMMMMMMk.                                            '0MMMMMd                                     ,KMMMMMMMO.  cW    //
//                                              cWMMMMMK, ox.                               oMMMMMMMx.                                            '0MMMMMo                                     ,KMMMMMMMO.  cW    //
//                                              cWMMMMMK, ox.                               oMMMMMMMx.                                            '0MMMMMo                                     ,KMMMMMMMO.  cW    //
//                                              cWMMMMM0, ox.                               lWMMMMMMx.                                            '0MMMMWl                                     ,KMMMMMMMO.  cW    //
//                                              lWMMMMM0, ox.                               lWMMMMMMx.                                            '0MMMMWl                                     ,KMMMMMMMk.  cW    //
//                                              lWMMMMM0' dx.                               cWMMMMMMx.                                            '0MMMMWc                                     ,KMMMMMMMk.  cW    //
//                                              lWMMMMMO. dd                                :NMMMMMMx.                                            '0MMMMWc                                     ;XMMMMMMMk.  cW    //
//                                              oMMMMMMO' dd                                :NMMMMMMd                                             '0MMMMN:                                     ;XMMMMMMMk.  lW    //
//             .::cccc;,'.                      dMMMMMMO. dd                                ;XMMMMMMd                                             '0MMMMN:                                     ;XMMMMMMMO;';kM    //
//              ...',;cloooooc;'.   .;,.        dMMMMMMO..xd                                ;XMMMMMMd                                             '0MMMMN:                       ....'',;::clooOWMMMMMMMWNWWMM    //
//                        ..,:ooolc;;lx0Odc,.   dMMMMMMk..xo                                ,KMMMMMMd                                             '0MMMMX:   ....'',;::cloodxxkO00KXNNWWMMMMMMMMMMMMMMMMMMMMMM    //
//                               ...'c0WMWXk:...xMMMMMMk..xo                                ,KMMMMMMd                                    ....'',;:dXMMMMWKkO00KXXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                    .:oxkkkxddKMMMMMMk..xo                                '0MMMMMMo                ....'',;::cloodxkkO00KXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXNM    //
//                                             .xMMMMMMk..xo                                '0MMMMMMx,,;::ccloodxkkO00KXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXKK0Okx0WMMMXo;od;..xM    //
//                                             .xMMMMMMx..ko                ....'',;:ccloodxONMMMMMMWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNXK00Okxddolc::;,'....    :NMMM0' ;c.  dM    //
//                                             .xMMMMMMk',0x',,;::cloodxkkO00KXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMWKKOxdollc:;,,'....                      :NMMM0' ;c   dM    //
//                                  ....',,;:ccdKMMMMMMNKXWWNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMXOkxddolcc:;,'oNMM0::'                                     :NMMM0' ;c   dM    //
//              ....',,;:ccloddxkOO00KXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKKXWMMMMMMMMMXOo:coxko.           ;XMMO;:'                                     cWMMMO. ;c   dM    //
//    cloddxkOO0KKXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKl'..;KMMMMMMMMMMMNx;...oO,          ;XMMk,:'                                     cWMMMO. ;c   dM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXXK0OOkxdooll0WMMMMMMMMMMMMMMMMMMMMMMWo    cXMMMMMMMMMMMMWX0kkXk.         ;XMMk,;.                                     cWMMMO. :c   dM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKKWKxxdolcc:;,''....      .:kNMMMMMMMWNMMMMMMMMMMMMMMK:     :KMMMMMMMMMMMMMMMXkOl         ;XMMk,;.        .:dkx;                       cWMMMO. :c   dM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXK00OkxddoldXMMMMMMx.,Ol                    .c0WMMMMMMMWkcOWMMMMMMMMMMMMMM0'     lNMMMMKxOXWMMMMMx.:0:        ;XMMx,:.      .lKWMMM0'                      cWMMMk. ;:  .xM    //
//    MMMMMMMMWWNXKK0OOkxdoolccc:;,'...        '0MMMMMMd 'Ol                   .xWMMMMMMMMWk.;XMMMMMMMMMMMMMMMk.     .oNMMMK; .,lkXMX;  lO;       ,KMMx,:.     :0WMMMMMk.                      lWMMMk. ::  .xM    //
//    ddolcc:;,''....         .'',;ccllool;.   '0MMMMMMo 'Oc                   oWMMMMMMMMMNc ,KMMMMMMMMMMMMMMMXl.      ;0WNKd. ....:,   .dk.      ,KMMx,;.   .oNMMMMMMX;                       oMMMMk. ::  .xM    //
//                                   'o0WMW0o'.'0MMMMMWl ,Oc                  .OMMMMMMMMMMKo''OMMMMMMMMMMMMMMMMK,       .cd,.  ;dol.     ,Ko      ,KMMx,;.  'kWMMMMMMNc                        oWMMMk. ::  .xM    //
//                                   .::;:lxKX00NMMMMMWl ,O:                  ;XMMMMMMMMMWKXkcOMMMMMMMMMMMMMMMNl                 .,.     :NO.     ,KMMd,:..cKMMMMMMMNl                         oWMMMx. ::  .xM    //
//                                          .;oKWMMMMMWl ,Oc                  :NMMMMMMMMMMMMWNWMMMMMMMMMMMMMMWk'                         .OX;     ,KMMd,loOWMMMMMMMXc                          oMMMMx. c;  .xM    //
//                                             ;KMMMMMWl ,O:                  cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo                          cNl     '0MMd,kWMMMMMMMMK:                           oMMMMx. c:  .kM    //
//                                             ,KMMMMMWc ;O:                  :NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.                         lWk.    '0MMo'OMMMMMMMMK;                            oMMMMx. c;  .kM    //
//                                             ;XMMMMMNc ;O:                  ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.         ...',;:cllc..:c:xNNc    '0MMo,0MMMMMMMNl                             dMMMMd  c;  .kM    //
//                                             ;XMMMMMWc ;O:                  .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK; .;lddl::::;;;;::cOWWo'kXkdkXK;  'xNMMo,0MMMMMMWd.                             dMMMMd  c;  .kM    //
//                                             ;XMMMMMN: ;O:                   oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXOOXWMMNc   ..',,,;:kWMO;o0ocdKM0dkNMMMMo,0MMMMMKl.                              dMMMMd  l;  .kM    //
//                                             ;XMMMMMN: ;0o;clooolc:;'.       ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkddddddddoollloxOK0xdk0KXNWMMMMMl,0MMWKo.                                dMMMMd  l;  .kM    //
//          .''',;;;,,,,'..                    :NMMMMMN: ;XWMMMMMMMMMMNKOdc;'...dWMMMMMMMMMMMMMMMMMMMMMMMWWNNXK0Okxdlc;,'..           ...   .'lkXMMMMMl,KNkc.                                  dMMMMo .c;  .kM    //
//           .....'''';:cllccccclc:;,'...      :NMMMMMN: ;XMMMMMMMMMMMMMMMMWNX0OKWMMMMMMMMMMMMMMMMMMMMWKl,''....                         .;ccdXMMMMMMWl,o,                                     dMMMMo .c,  .OM    //
//                            .;dxkkkkxdolc;.  :NMMMMMX; ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc.                           .';:clxkkk0WMMMMMMWc,;                                     .xMMMMo .l;  .OM    //
//                             .;:cloddxxkkxollOWMMMMMX; ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:                      ..';:ldxkO0OO0KNMMMMMXxxXMWc,;                                     .xMMMWo .l;  .OM    //
//                                     ...',:kWMMMMMMMX; :NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,            ..',:cldxO0XNWMMWNNWMMMMWN00NMMk.'0MWc;;                                     .xMMMWl .c,  .OM    //
//                                           cXMMMMMMMX; :NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,..';::cloxkO0XNWMMMMMMMMMMMMMMWN0xoc;'.;KMMWl,0MWc,;                                     .xMMMWc .c,  .OM    //
//                                            'kMMMMMMK, :NWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN00XWMMMMMMMMMMMMMMMMMMMMMMMMN0o:..      '0MMXlcKMN:,;                                     .xMMMWc .l,  .OM    //
//                                             lWMMMMMK, c0c;okKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;.  .','...  cNMXdxNMN:,;                                     .xMMMWc .l,  '0M    //
//                                             lWMMMMMK, cO'   .,cdOKNWWMMMWWMMM0dxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMK:..:dOXWN00XXd.cNW0oOWMN:;;                                     .kMMMNc .l'  '0M    //
//                                             oWMMMMM0, lk.        ..',;;;;;kMWKo,'kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOlokNNO0NWKOOx:..cdl:OMNKXMMMX;,,                                     .kMMMN: .c'  '0M    //
//                                             oMMMMMM0' lk.                 dOxXMXc:KMMMMMMMMMMMMMMMMMMWXKKXNMMMMMMMWKOxc',0MMMMWKxlcccl;  '0MMMMMMMX;,,                                     .kMMMN: .l'  '0M    //
//                                             oMMMMMM0' lO.                .xolNMMNKNMMMMMMMMMMMMMMMMMXd::,.,kWMMMXx;.    .coox0X0dcxKx,   .kMMMWXNMX;;;                                     .kMMMN: .l'  '0M    //
//                                             oMMMMMM0' lk.                .dxxMMMMMMMMMMMMMMMMMMMMMMMXOKNKxd0WMMM0'          .c:..;;.      oWMMKxKMK;;,                                     .kMMMN: .l'  '0M    //
//      .;:clllllc::;;,'''',,,''''''.......    dMMMMMMO. lk.                 :kd0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:    ';     ':;'.        :NMWl:KMK,;,                                     .OMMMX; .c.  '0M    //
//       ....'''''''..;okOkkkxdooddolc::;;:;.  dMMMMMMO. ok.                  lklxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,    :d.               .;kNNd.,KMK,;,                                     .OMMMX; 'l.  ,KM    //
//                     ',;:ccc::::c:;,,',:;.  .dMMMMMMO. ok.                   cxc:xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;    ;d.              .kXx:,  ,KM0,;,                                     .OMMMX; 'l.  ,KM    //
//                          .';clooollc::ll:'..dMMMMMMO. ok.                    ,xl..,;;xNMMMMMMMMMMMMMMMNXO0WMMMMMM0,    .             .:0MN: .;.,KM0,;,                                     .OMMMX; 'l.  ,KM    //
//                           ...,;;;;;;;::cllclKMMMMMMk. ox.                     .xo. 'oKWMMMMMMMMMMMWN0d,..dWMMMMNOx;                .oXNXNW0kKx.,KM0,;,                                     .OMMMK, 'c.  ,KM    //
//                                         ,;.'OMMMMMMk. dx.                      ,kxkNMMMMMMMMMMMMM0:'    ,KMWKOkccOl                 :Olod;:c;. ,KM0,;,                                     .OMMMK, ,c.  ,KM    //
//                                         .cxkXMMMMMMk. dx.                       'xNMMMMMMMMMMMMMMx. .'..dWMK;..:XX:       cl..        .oc      ,KMO,:,                                     '0MMMK, ,l.  ,KM    //
//                                           cKWMMMMMMk. dx.                        '0MMMMMMMMMMMMMNl .xOc:OMMWKkkXM0:.  .'cxd''kc       'x;      ,KMk';'                                     '0MMMK, ,l.  ;XM    //
//                                            '0MMMMMMx. dx.                        '0MMMMMMMMMMMMMk. ck,,o0MMMMMMMMMNKOO00o'   ld.      :k'      ;XMk';'                                     '0MMM0' ,c.  ;XM    //
//                                            .kMMMMMMx. dd                        .lNMMMMMMMMMMMMMd .l, 'd0MMMMMMMMMMMMMM0c'.  .l:     .dd       ;XMk';'                                     '0MMM0' ,c.  ;XM    //
//         ..                                 .kMMMMMMx..xd                     .,o0WMMMMMMMMMMMMMMK;'. .dXNMMMMMMMMNkcoKMMWNKOx;;l.    ;Kc       ;XMx':'                                     '0MMM0' ;l.  ;XM    //
//        .ol.                                .OMMMMMMx..xd                    .kNOdXMMMMMMMMMMMMMMMO''oKWMMMMMMXOxo'   'llcc:cxd'.    .kO'       ;XMx':'                                     ,KMMMO. ;l.  ;XM    //
//         .;:::cclllcc::;,''''''''.......    .OMMMMMMd .xd                    ;XNc.oWMMMMMMMMMMMMMMK;lWMMMMMNKKOoc::::cldxkkdoxkl.    oXl        ;XMx';.                                     ,KMMMO. ;c   ;XM    //
//                ....'''''.....',,,,,,;,.    .OMMMMMMd .xd                    :NWk..dWMMMMMMMMMMMMMx.,dlcclod:...,ccll;;x0xc'.  .    :XNc        ;XMd':.                                     ,KMMMO. ;c   :NM    //
//                              .c:;,'..      '0MMMMMMd .xo               ..''c0Xlll..oNMMMMMMMMMMMWl             .::;'. .. ...      'OOkO,       ;XMd':.                                     ,KMMMO. :c   :NM    //
//                               ,oxkxdddoodddONMMMMMMd .ko      ...''...,kNNWNk' .l:  :KMMMMMMMMMWd.      .cxo:,';cdkOOO0Ok0K:     .dXkdOO'      ;XMd':.                                     ,KMMMO. :c   :NM    //
//                                     .:dkKNWWMMMMMMWo .ko .;ldOKXNNNNNXNMMMMNc   .dc  .oXMMMMMMMWc        .cx0K00kdl:;;:cc:'      cNWWO;dO,     ;XMd';.                                     ,KMMMk. ;c   :NM    //
//                                        .';lkNMMMMMWl .kKkKWMMMMMMMMMMMMMMMMWo    ;0Ol. .dXMMMMMWo           ....                ,KNNMK,.oO:    ;XMo':.                                     ;XMMMk. ;:   :NM    //
//                                            ,KMMMMMWl .kMMMMMMMMMMMMMMMMMMMMMNo.   cNX;   cNMMMMMXOd'                           ;0O;dMN:  oXx,  ;XMo'c.                                     ;XMMMk. ::   :NM    //
//                                            ,KMMMMMWl .OWWMMMMMMMMMMMMMMMMMMMMWx.  .dNl   ;XMMMMMMMMXo.                       .d0o. lWX;  dMMNk:lXMo'c'                                     ;XMMMx. :c   :NM    //
//                                            ;XMMMMMWc .Od;xXMMMMMMMMMMMMMMMMMMMMKc. .x0,  ;XMMMMMMMMMW0l;'                 .,d0x,                                                                               //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract IGJB is ERC721Creator {
    constructor() ERC721Creator("Igor Jacobe", "IGJB") {}
}