// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FAKE NEWS by COLDIE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMW0xxxxxxxxxxxxxxxxxxxxxxxxxxxxxONMMNOxxxxxxxxxxxxONMMMMMMMMMMMXOxxxxxxxxxxOXMMNOxxxxxxxxxx0WMMMMMMMMMMMMMMXkxxxxxxxxxkXMMMMMMMMMMMMWKxxxxxxxxxx0WMMM    //
//    MMX;                             '0MMNk;.           :0WMMMMMMMMMk.          .kMMNd.         .dWMMMMMMMMMMMMK;         .lXMMMMMMMMMMMMWl          ;XMMM    //
//    MMX;                             '0MMMMNk;           .oXMMMMMMMMk.          .kMMMWk'         .:oooooooooooo'         .dNMMMMMMMMMMMMMWc          ;XMMM    //
//    MMW0xxxxxxxxxxxxxxxxxx;          '0MMMMMMNk;           'kNMMMMNO:           .kMMMMW0;                               'kWMMMMMMMMMMMMMMWc          ;XMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMd          '0MMMMMMMMNk;           :0XOl,             .kMMMMMMXc           .......           ;0MMMMMMMMMMMMMMMMWc          ;XMMM    //
//    MMMMNxcccccccccccccccc'          '0MMMMMMMMMMNk;          ..                .kMMMMMMMNo.         c0KKKKx.         cXMMMWx;;;;;;;;;;;;;.          ;XMMM    //
//    MMMMK,                           '0MMMMMMMMMMMMNk;                          .kMMMMMMMMWk.        .dWMMK;        .oNMMMMN:                        ;XMMM    //
//    MMMMXo;;;;;;;;;;;;;;;;.          '0MMMMMMMMMMMMMMXl.            .           .kMMMMMMMMMW0,        .dWK;        .xWMMMMMWkccccccccccccc.          ;XMMM    //
//    MMMMMMWMMMMMMMMMMMMMMWo          '0MMMMMMMMMMMN0o;.          'lOd.          .kMMMMMMMMMMMK:        .c,        ,OWMMMMMMMMMMMMMMMMMMMMWc          ;XMMM    //
//    MMMKolllllllllllllllll'          '0MMMMMMMMNOl,.          .:kXMMk.          .kMMMMMMMMMMMMNo.                :KMMMMMMXdclllllllllccllc.          ;XMMM    //
//    MMMx.                            '0MMMMMNkl'           .;dXWMMMMk.          .kMMMMMMMMMMMMMNx.             .lXMMMMMMMO.                          ;XMMM    //
//    MMMO;.'.''..''''''''''''''....'''cKMMMXkl,'''''.''.'';oKWMMMMMMM0;''''''''..;OMMMMMMMMMMMMMMWO;'''.''''''',xWMMMMMMMM0:'''''''..'''''''.'''''''''lNMMM    //
//    MMMN000000OO0XNNNNNNNNNNXK00000000NMMMWNXK00000000000KKXXXXXXXXXK00KNNK0000O0KXXNMMMMMMMWXXXXKK000XNNNNNNNXKXXKKXXXXWWNNNNNNXK0OkkkxxxkkO0KXNNNNNNMMMM    //
//    MMMO,........;xXWMMMMMMMK:........dWMMMM0:.........................oWWd.........:KMMMMMNl.........cXMMMMMXc........oNMMMNOo:,....       ...':lkXWMMMMM    //
//    MMMx.          'oKWMMMMMK,        lWMMMMO'                         lWMK,         lNMMMNl           cXMMMWd.       '0MMNx'       .';;;'.        .dNMMMM    //
//    MMMx.            .c0WMWMK,        lWMMMM0'        .oOOOOOOOOOOOOOOOXWMWk.        .kMMWo.            lNMM0'       .xWWMk.       .c0XWWWKd,.....'';OWMMM    //
//    MMMx.              .:kNMK,        lWMMMM0'        .cxxdxxxxxxxxxxxKMMMMWo.        :XWd.      .      .oNNc        lKo:OK;         ..';:cclloxOKNNWWMMMM    //
//    MMMx.        ..       ,kk'        lWMMMM0'                        oMMMMMX:         ox.      ;k:      .dd.       ;Kx..xMXx:'.                .';oONMMMM    //
//    MMMx.       .x0c.       ..        lWMMMM0'         ';;;;;;;;;;;;;:OMMMMMM0,        ..      ,0MK;      ..       .Ok..lNMMMWN0kdoc:;''..           :0MMM    //
//    MMMx.       .kMWKo'               lWMMMM0'        '0MMMMMMMMMMMMMMMMMMMMMWx;.             .OMMMK,             .dK:  lOdoollllcl0MWWNX0Od;         lWMM    //
//    MMMx.       .kMMMMXx,             lWMMMM0'        .cdddddddddddddddkXMMMMMNXl            .kWMMMM0'            :Ko.  'o,        .oO0XXXKk:        .xWMM    //
//    MMMx.       .kMMMMMMNk;.          lWMMMM0'                         .kMMMMMMMX;          .xWWWMMMWO'          ,Oo'lo. :0o'         .....        .c0WMMM    //
//    MMMO;''''''':0MMMMMMMMWOc'''''''''xWMMMMKc''''''''''''''''''''''''':0MMMMMMMM0:'''''''..,l:;;dNMMWk;''.  .'';o:'xWWk..;xd.   .     ......',;cdOXWMMMMM    //
//    MMMWWNNNNNNNWWMMMMMMMMMMWWNNNNNNNNWMMMMMWWNNNNNNNNNNNNNNNNNNNNNNNNNWWMMMMMMMMWWNNNNKkl;,:oxOk0WMMMWWNN0,,xdcc'.kWM0:';,...cxO0ko. .xKKKXXNWMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkoccokXWMMMMMMMMN0OXWd.c;    ;KMNc ':. ,xKXXXOc. :XMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl:lxKWMMMMMMMMMMXd,. cO,       ,0M0'':. .........'oXMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkd::dXWMMMMMMMMMMMNd',od',:..   ...dNNc.kx.'kOdoodxO0NMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO' 'xNMMMMMMMMMMMMMWo '0Xl'c, ..  ,oKWWd;OWNx,':loxkOOOkxdolo0MMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO,.,xXWMMMMMMMMMWXx:. .:;;kx;.   ;KMMMN0XMMMMNkoc. ..''.,:lldKMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0klcldOKXNNX0dc:cdOdlokNMXO:.,l0WMMMMMMMMMMMMMMXOOKKKXNMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdllloooldkXWMMMMMMMMWd.oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMO.:XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk'dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWl;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:oMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXoxMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FAKENEWS is ERC721Creator {
    constructor() ERC721Creator("FAKE NEWS by COLDIE", "FAKENEWS") {}
}