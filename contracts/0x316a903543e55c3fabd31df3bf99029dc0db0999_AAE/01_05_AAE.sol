// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AnnAhoyEditions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNXXKKK000000000KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kdlc;,'.........;;'. ...',:cok0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKko:,.                .:lodc.        ..;ldkOOOOO00KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX00OkxxkO00K0koc;'.                         'okd,.,.             .....;coOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWX0xl:,.............                  .'.            .o0KKOo.        .;oxo.      .;oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMNOd:. .,cccccccccc:.      .cddooolc;.    .cxkd:.          'o:.ck;     .l00d;.           'lkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMN0d:'     .ckxc.               ';;:clodkkkd:.   ,oO0d'             ,d;   .xKo.                 'cxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWNXX0d:'.  ..';coolodo,                        ..,;.     .;k0c             .;.  ,o,                 .;,'.':coxk0KXNNWWWWWWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMWx;'..,clclolcllc:,..                                         cOc.    ,:.                             .:looolooo;....';;,,,,dNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMWx.   ..'',;,'..                                   .....       .'.    .cxo'            ';.                  .:KNklccc:;.   .oNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMW0c'        ..'''..                ....       ;dxxdxO00ko;.            .o0d.       .ck0c          ....      .',;,,'..   .;OWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNOo:'...      .'''..    .,:looollcc,     .:OKd;;xXWWMWKkl.            lNk.    .lKXd'       .;odk0K0d:.             'cOWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWNXKOo'        ..;oxO0xl:,..           dK; .kMMNkdXNdoOo.     .l;  .kWo    oW0,  .    'oKWXkc,;dXXo.    .      ;KMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWO:.           .o0WNx;..             cl  .OMMMo ;Xx..dkc,.   lOl. .dx'  .k0, .ll..',:0MKkKNd. 'kx'   .ll'    .kWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWKl.         ,ldkOkdl:'..''''.              ,xOx, .l;  .oOOo.   ;O0d,.     ''.:kd';;. .OMO',0Wo  ;c      :xl'.'',oXMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMW0l,.........  .l0NWXd.        .'''..                               .:OXd.    .c00c. ..   ;o;  ,d,  .'      .:k0l.   .oKWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMM0:.      .,coxkxddxko:'             ......                             .cO;    cNk.                      ..'''.,OK:     .oXMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMXko:'.  .:llc;,..  ...........          ......                           ...   'c.                    .'''..  .dWKl.  .lOKWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMXd,.                     ...........      ...    ..               .';cdk000xlclol;.              ...'.       .xKc   .:OXWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWKo'                               ...........      ,l. .l,          ,ldkOO0XMMMMMMMWKxl.           .           .:0Xx:;;;,':kNMMMMMMMMMMMM    //
//    MMMMMMMMMMNOd:,,,,,,,,,,,,,,'''.......                 ...          .,.  ..          .;cOWMMMMM0olc,.   .,..;..l'    ..',;,;;;,lKo.   ..:OWMMMMMMMMMMM    //
//    MMMMMMMMMKo;.. ....  .........''''''''''...............                               :OWMMMMMMXx;             .. ...'''..      ,xd.  ;OWMMMMMMMMMMMMM    //
//    MMMMMMMMMWNNK0ko,.                                            'c. 'o. .:.              .;ok00kd;.      .'  ..                    .,.   'dXMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWKl.                                              .'  ..   ..                              .'  '. ,;                         .dXMMMMMMMMMM    //
//    MMMMMMMMMMNk:.                                ...........                       .,:cc:'. ..                      ...'',,;;;;;;;;,,,,,,,,;:oKMMMMMMMMMM    //
//    MMMMMMMMMMKl'.          .:,       ...'',,,,''''''....                     ..,cdkkkdoodxdoooooooool'               .......'''''',,,'''',dNMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNKOd;.    ...ckklc:;;;;;;,''..                    .,,'''';coxxkkxddo,    '''. ...'..'cool;.                                 :KMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNxc;;;;;;;;;,,:xkl.                       ,oxolxxoddxxxddK0:. .oKXK:  :0xOdoxlo' ,cc:,,cxkl;'.       ..,,,'..              'kWMMMMMMMMMM    //
//    MMMMMMMMMMMMXd;''..           .coo:.                   ,KMMMMW0,       ;Kl  'OMMMd  ':':,:ccd,:NMMWx..xMMMXx.        ..,;:cclll:,:o,  'codKWMMMMMMMMMM    //
//    MMMMMMMMMMMMWKxc;''.           .;clol:.                ;XMMMMMMk.      .kx. .xMMNc            cNMMWo .kMMNx.                .:kNKkxoloKMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWOl.           :KXkdk0Od:.             .dWMMMMWo       .kx.  dMMk.            ;XMM0' ,0MXc                'cdkxc.  ..,dNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWO;             'dXNklok0o.             .oNMMMO.       .Od   dMK;             ,KMNc  oWK;            .':dkxo;.        .kMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNk,             'd0x,..                 :KMMk.       .Ol  .xXc              cWNl  ,K0,          .cdxxo:.       .:lodxKMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNkc'.           .oOx;                  'OWNc       'Oc  .dc              .xKc  .x0,          .l00xool.       .oNMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMXl.             .ckx:.                .oXXl      ,O:   .               .:,  'kk'             'lOXk:.    .':oONMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNx'           .okdx0NKo'                ,ONd.    'Oc                       :Oo.           .:dkkl'     'dKNMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMKl.          'o0NXOkOk,                .oX0;    od.  .lk'              .ld,          .cdxd:.      .'cOWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWXd;.         .;dkd:.                   ;0Xd.  .o:  cNK,         'd, .:,         .:x00k;     .':d0NMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxl;..       .cxko,.                 .xNKl' ,:.,OM0'         dWl ..          .:d0XO;   .;dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'          'cxko,                .cXMNOx; :XMK,        ;KWo            .cxOx;.    .,dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk;            'cxxl,.              ;0MMk. ;XMNc       .kMNc         'cxOxc.    .,oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:.            .cddo:'.           ,0Mx. '0MMk.     .oWM0'       ,dkd:.    .;o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;..           .,cc'            'OXl..,x0o.    .dNMWo        ..        cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0koc,..                       .dKN0occc;,.  .lkx:.                'l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0k:..                     ';cdkOkdllllcc;.               .ckNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l'                                ...             .,lkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkl,.                                           .;0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxl,.                                    .:oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xc.                               ,kXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo;.                       .;lxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxo:,..            ..:oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKOkkxxdooooxOKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AAE is ERC1155Creator {
    constructor() ERC1155Creator() {}
}