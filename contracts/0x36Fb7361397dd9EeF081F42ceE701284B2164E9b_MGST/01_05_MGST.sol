// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mugshots by cydr
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                     .',,''..',,,,,,;;:;,;,,'..                                                               //
//                                                              ..'',:oOKKXX00O000O0KXXXX0Oxdddolc,..',.                                                        //
//                                                           .;odxO00KXNNKXWNNWWWWWNK000XXXOOK0OOkxdodoc,..                                                     //
//                                                     .',;cdkOKX00XXXNWWWWWWWMWWWNXNNXXNWNKXNNXXXNXKKxlclc;.                                                   //
//                                                  ..;kXNWWWNXKXXXXXXKXNNWWKXWNNWNNWMWXXKXWWNXKXNWNXKOO0KOdc. ..                                               //
//                                               .,cloxKNWWWMWWN00XXXXKXNX0x;cOKNWWMMMNKKXXXK00KKKXXXKKXNNKxdxlc:,'.                                            //
//                                             'o0K0K00XNNNNWWWN0OKXXXXNNXOooxKNWWMWNNK0OkxxxOOOkxxOKKKKKX0kkOkdool,...                                         //
//                                           'cxKNMMMWWWWNK0XKKXXOO0kdx0XNNNWMNNWWWWX0Okx:,:dkOkxxdoxkkO0OOOxloxxxl;cl,                                         //
//                                         .lOkkKWWWWMMMWXOxO0KKOOOOd;:xOKWMWWWNWWWWNK000xxxkxdc;;',odxkkkxxd::loc:okxc,..     .....                            //
//                                      .;lox00XNWWWMWNXKOk0K000kOOdc,:dOXWWWWWNWWWMWWWNNX0xxkxc.   'lxOxoxkdc::;,;l:,;,;c;.      .'.''                         //
//                                     .o0KNWWWWWWWWNNXXXOk00kx00OOxc;lxk0NWNNWNXKXXNXK0OOOxxxl,     .'codOKOo:ldc:l:...,cc;,..      ...''..                    //
//                                    ,kKKXNWMWWWWNNWWWWWK00Okxxdddc;;o0XNWNKK0OkxOXXKOxdxdoc:'         .:dxd:,,cllxddo;.. .,:;..:;     ..''                    //
//                                   :kKKKXNWMMWWWWWMWNNN0xdxdoolldolclxOXWKc'.';cdOO0K0KK0kl;.          ..:lclc;lxkxdllc'   .'..''                             //
//                                 .c0KXXKKXXNMWWWWWWNK00K0xdoc:cccooccddkKx.   .;lkOkkk0KKKXKx,           .:oxd:;clolcc:co;  .oOl..:'                     .    //
//                                .lKXXX0KNWWWNNWWWWNK0KKXXk;',:dkxxdooxdc;.     .,oxkxddxddk00d'           .''';c;..,:lclkx:..'lxd:,.                          //
//                               .oXXKKXKKNMMWNXWMMWNXNXNWKo...'co:,,....          ..',';::cloOOd,           .. .'.'c:,,'.:lodc::oOxc'.,,                       //
//                               :KWNNNWWWWWWWMWNWWMWWWWMNO:'.....                         ..,odo:.            .    .col;.. .lxxdx0Oxdlcl:.                     //
//                              .cOXXXNWMWWWXNMMMMMMMMWMWKkd:.                                 .....       ..         .;od:. .:lxKNX00Kkc;,.                    //
//                              'dO0KKXWWNNWNNWNWMMMMWWNKK0d,                                             ..,,. ....    .lko;..;xXK0XNXKOdl:,.                  //
//                             .lOk0K0KNNNWWNWWNNMMMMWNNNKOx,                                             .,:clc.        ..coll:c0XXXXKKKkdddd;                 //
//                             'oO000O0XWNNWMMMMMWWWNXXNNKl.                                              'clc::c:'.       .';coldk0XXNX0xodxx:                 //
//                            .coxKK0KXNWNNWMMWWWWWWX000kl.                                                .. .oOl::;,.       ,k000KXNXOxxxkkOo.                //
//                            ;kkx0XXXNNNNWWWMMWWWWNXK0d;.                                                     .',:odoc'      ;KXXNNXXXOddk00x:.                //
//                           .dXKKKXNWNWWWWWWWWWNNNKOKKl.                                                        .;oxxocloc.   :0NNWWWNKOk0KOdc;.               //
//                           'x0KXXNNNXWMWMWWWWWNXXNXKx,                                                           ,dkO0000k:',l0NNNNNNNX0KKko;'.               //
//                          .:dxkO0O0XNMMMMMMWWWNNWN0l.                                                             ;k0KkdOX00K0O0KXNXXNNOkOko;',.              //
//                          'k00Odod0WMMMMMMMMWWWW0c.                                                                :0X0OOKKXWNNNXNNNNNKOOkkkdoxc              //
//                          ;k00OxdkKWMMMMMMMMMW0l.                                                                  .cOKNNNXNNWWNWWWWNNXkxxddloo;              //
//                          ,x0xx0KKNWMMMWMWWMWO;...''.';,.                                                           .oNWWN0KNWWWWWWNNXXXKkllodkl.             //
//                          .okkddkKWMMMWWMNNWWKddkkOOc'..  .':codc,,;,....   .  ..        ...   ..   ..               .;dKNKKNNNNNKO0XXKKKOolc:l,              //
//                          .lO0koo0NWMMMMMMMMWKl'...;l,     ,dxOd.  .;,;oocclc:ldo:. .';,....       'cc,.                .lOXKXNNNXKXXXXK0Okkxdl,              //
//                           ;OKOxd0WMWNWMMMMMWo      :l.      .''   ...'cxkoc::coll, .lx,..',,;:c:cokKXNO:.                .:0WNWWWWNXKKK0kO0xol'              //
//                          .l0KOOKNWMX0XMMWWWWx.   .;oxc.       .;dk0KXNWNOc:lldkkd'  lXKO0KNNNNXXX00NNXx,.,,.               ,OWWNXNX00KXK00Oo;.               //
//                          ,x0KOkxkNMMMMMMMMMMNd..cKNNNXd;..'cxOOXWWWMMMWKxdk00kOOkl. ;0WWKdd0NNNNWNNNNNOddo,..            .. dWMMWWNNKKXXXKKk:.               //
//                         .ck00xcckNMMWWMMMMMMMWKOKNWWWWWNK0KNWWWWWOccOWWkxKN0c...:xo. 'kNKdokXNN0kKNXXNNXkc,,;;'          ...xWWNK00OOXXOxkkd:.               //
//                         c0O00koxXWMMWWWMMMMMMMWNXNWOolccxXWWWMMMXc..:kKKK0c.     .'.  .dNWMWN0o',kWWWWWX0d;.'lOo.           :0NWWNN00X0klclo;.               //
//                       .,xOO0OkkKNWMMMWWWMMWWWMMWWWK;    .:xXMMMWk:odccxKO;             .kN0dkOxdkXWMWWWNKkl:;,cxl.     .,.   ;kXNNXKXNKkdddl'                //
//                       .lOdd0OkxkXWMMMMMMMMWWWMMMMMK,   ,OOdkXNNNk:.  cKd.               ;Oo..dNNKXWMWWWNNNXN0c;xKl    .'. ..cOKKXNXKXXK0kOx;                 //
//                       .cxdk0kxdxKWMMMMMMWWWMMMMMMMXl   .xNKdlcxKKd'.cOd.                 ..  cKX0XMMWWNXWWWWXklxXk'  .'..:kXNWWWWNNXXK0Oxdc.                 //
//                        :kddkkkxx0NMMMMMMWNWMMMMMMMW0;. .oXxcccd0kdoxk:.                     .xNNWMMWWWWWNXNWN0dcdkc.    .dNNWWNWNNNNNX0xo;.                  //
//                        c0kx00dxOO0NMMMMMMWWMMMMMMMMMNOll0Ko''o00kOKd.                       .cONWWMMWWWN0XNNN0l'cO0d...:xKWMWWNKOKNNXX0x:.                   //
//                       .okdkKNNXKKXWMMMMMMWWMWWMWMMWWMWNNWN0kx0XKkc'.                          'dkKWMMMMNNWWWWX0O0K0OdxKNWMWWWWWWWWXOdl:'                     //
//                       :d:ck0XWXKKKXWMMMWXK0kkOOO00Ok00K0OOxddl;.                         .:l'    .cokKXKKNNXX0kxxddxxxKMMMWWWWN0KKOdc;'.                     //
//                      .oOooxxOKKKX00XWWNx,..     ..  ......                                .',''. ....cdo:cllxkdodxxkkxkKXNWNNWNK0K0dc;.                      //
//                      ;OOkkO0KXNNXXXNWWNl.                                                      . ........  ..'.','..,''lOXWWNNNNX0Oo,                        //
//                     .oKKXXXNWMWNNN0kXWWo                              .'.                                             .kWMMWNNXK0xc'                         //
//                     :OXKKXXXNNNNNNK00XWd.                            ;kK0:          .cd:.                             ,0MMMWKOO0Oc.                          //
//                    ;kXXXNXXNNNNNNNNK0KNO'                             .'..           ...                              :KWWWN0Okdl.                           //
//                  .o0XNXNNNNNXXKXNWWWXNWNo.                                                                           .cONNXK0kl'.                            //
//                 :O0KXXXXNNWWNNNNXNWWNXKNK;                                                                           'kNNNKkdo;                              //
//                ;OKKKXXKXWWWWWWWWXXWWNK0XNd.                                                                         .oKNNX0kkl.                              //
//               .kKKKXXNNNWWMWWWWWWMWWNNXNNO:                                                                        .oKWNXX0Ox,                               //
//               ;kOxO00KXKXNWMWMWWWNNNNNXXX0l.                                                                       'xXXKNNKkc                                //
//             ,okkkKKK00KXNWWWWMMWWWWWNXXKKKkl.                                                                     .c0NX00KOc.                                //
//            .oO000XXKXXXXNNWWMMMMMMWWWWWNNKKO:                                                                    .oK0KWN0dl'                                 //
//           'oddxdxkOO00KXKXNWMMWWWWNNNWWWWWWNO,                     ....          ....                           .lXNKKWWKo.                                  //
//          .xOxxdooddxxkOKKKKXNWNNXNXNWWWWWWWWWO'              ..   ..'..       ..,;''''...                       ,OXNWXOxd:                                   //
//          ,kOollc:ccdkk0XNNXNNNNNNNNNNNNWMWMWN0l.           ....                                                .oXKXX0xc.                                    //
//          ;kxdxdoddclxOKXNNXK0KKXNWMNXXWWWWWWNNKc                                                               :0NNX0kd,                                     //
//         .:dl:looddox0KKKXNNXKK0O0NWMMWNNWWWWMMWXo.                       .                                    cXWXXKOo'                                      //
//       ':clddddkO00O0XNXNNNWMWWNXKNWWWWWWMMMWWMMWXd'                    .;clllloddc,.                         ,OWNXNNO'   .                                   //
//     .;ccoxxxddk0KKKNWWWWNNWWMMWNXNNNNNWWMMMWWWWWW0;                    .';;cloxkkdc.                        'xXNXKKk;  ..                                    //
//    'lxxoodxddOXXXKKNWWWWWXXNWMMWWNNWWNNWMNXWWWWWWW0:.                        .....                         .oNWNK0o.  ..                                     //
//    dddxkOKXXXXXXNXNNWMMMWWNWWMWWNNNNNNNNMNNWWWWWMMW0c.                                                   .cxKXXNXo. .'.                                      //
//    kkocoxO00O00XXXNXXNWMWMMWMMMWWWWWWNWMMMMMMMMMMMMNKd.                                                 .dXWWXX0:  ,o,                                       //
//    xxocokkOkkxkOKKKKKNWMMMMMMWWWWNWWWWMWMMMMMMMMMMMMN0c.                                               ,xXNNWKo'  ;l'                                        //
//    OkdkO0K0OkkkOKXXXNWWWWMMMWWWMWWWWNNWWMMMWMMMMMMMMMW0:.                                            .dXNNNN0c. .od'                                         //
//    ddxkOKKOO0KKKXXXXNWWWMMWWWWWMMWWWNNNNWMMWWWMMWWNWMMNOl'                                          'xNWXO0x,  .lx,                                          //
//    dkOOOKKKKXK000000KNWMMWNNNKKXWWWWWXXNWMMWWWWWWNNWMMMWX0c.                                      .oXNNNX0o.  .x0:          .;;.              .              //
//    XK0OkO0000OkOKXKKKKXWMMWWNNX0XWWWWWWWWWWWWWWMMMMMWMMMMWKd;.                                  .cKWWWNWXo.  .xKl      ...,:llooc;.                          //
//    kkKKKK00KKXXNNXXNNWWWWWNWWWNKXWWWWWWMWWWWWWWWMMMMMMMMMMMMXOd;.         ';'''''..            .dNWWWWNO;   .x0c    .;'',,,'. .:c,.                          //
//    OKWNXXNNNXXNNXK00KXNWWWNWWWWXNNNWNXNWMWWWWWWWWMMWWMMMMMMMMMWN0xdlc,.',ck0OOO00kdc.        ,xKWMWWNKl.   'kk'   .'.coxkdlc;'...                            //
//    KNNNNXXKXXXNNWNXKKKXNNWWWWMMMMWNWWNNNWWWWMWWMMMMMMMMWNNWMMMMMMMMWWNKKXXWNKXXNWWNN0xc:,,;cxXWWWMMXd'    :Od.   'clcl:;;:cloc,.                             //
//    O0KXXK0O000XWWMWWNXNNNXNWWWWWMMMWWWMMMNNMMMMMMMMMWWMMNNWMMMMMMMMMMMMMMMMMWMMMMMMMWMWWNXNWWWMWWWKl.   .dOc.  ,odc,cc;...;;..                               //
//    KK0OO0XXXKKKXWWWWWWWWNNXXXXXNNWWWWWMMWWMMMMMMWWNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWX0x'   .cOx'  ';;cc'.,,,,,.                                   //
//    XNK00KXXXXKXNWWWMWWNWXKXNXXX00XNWWMMMWWMWWMMMXxxXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMNNWMNk,... .,ll'..;oc;,,'';:,..                                     //
//    00OO0KXXKKKXNNWMMWNNXXXNNWW0xONWWWNNMMMMMWWWW0dkNWMMMMMMMMMMMMWWWWMMMMMMMMMWWMMMMMMWWMMWWWNc     ..  ..:ll:'.','..                                        //
//    KkxKNNNNNXXXXNNWNXXXXXWNX0OOKXXWWWWWWMMMMMWWXxdkXWMMMMMMMMMMMMMWWWMMMMMMMMWWWWMWMMMW0dlckNk. .;.  .;oc.  .'.                                              //
//    0kOKXK0KXNWXKKNWWNNWMMWWWX0KNNNWWWWWWWWWNXKOxd0NWMMMMWWMMMMMMMMWWMWMMMMMMMMMMMWNKko;.   ,xc .kNOxodxo;,,'.                                                //
//    000KOxxOKXNXKKNWWWWWWMMWNWNXNWWWMMWWNWWWKx;.;kNWWMMMMWWMMMMMMMMWWMMMMMMMMMMMMMM0;   ..;oxo.  ckxkd:ld:...                                                 //
//    00OOOO0KKKKK000KXWMMWWWWNWMMMMMMMMWWNXOl.  .xKNWMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMWNOoolokKNk.   ,lcol;cc.                                                    //
//    00KKkk0KKXKKXNNXXXNX0O0XNWWMMMWMWWWWWXd.  .oNWWWWNNWMMMMMMMMMMMMMWWWWWMWWWXKXKO0XXXOdlOXd.  .okxc'                                                        //
//    NXXK0OkxkOO0KXNNXXXKkkKXNNNNWWMMWWWMMWKc.,oO0xOKNXkdxXWXO0NNXNWWWWMWNWMWWXOkd;...''';:kO,  .llc'                                                          //
//    KX0kOkdx00KXKXNNNK0kkOKXXXKXNWXXWWWMMMWKOKXNNKKXXX0xOKKOxkKOxk0NWWWWWWMWWWNNXxc'      lk'   .                                                             //
//    OKKKK0Ok0000OOKKKKOkxk00xdkKNWNNNNMMMMNKOO0XWWWWNNNXNNNNXKKKKOOKNNXNNNNX0OO00d:.     .ll                                                                  //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MGST is ERC721Creator {
    constructor() ERC721Creator("mugshots by cydr", "MGST") {}
}