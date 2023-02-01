// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Zanjani Fashion Atelier
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                    ,O000000000000000000000000000000000O;                                                             '.                                      //
//                    cWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                                                            '0x.                                     //
//                    ,xkkkkkkkkkkkkkkkkkkkkkkkkkOXMMMMMX:                                                            .dWN:                                     //
//                                               '0MMMMWo                                                             :XMMO.                                    //
//                                              .dWMMMMO.                                                            .OMMMWo                                    //
//                                              :XMMMMN:                                                             oWMMMMX;                                   //
//                                             .OMMMMWd.                                                            ;XMMMMMMk.                                  //
//                                             oWMMMM0'                                                            .kMMMMMMMNl                                  //
//                                            ;KMMMMNc                                                             lNMMMMMMMM0,                                 //
//                                           .kMMMMWx.                                                            ,KMMMMMMMMMWd.                                //
//                                           lNMMMM0,                                                            .xMMMMWkkWMMMN:                                //
//                                          ,KMMMMNc                                                             cNMMMM0''0MMMMO.                               //
//                                         .xMMMMMx.                                                            '0MMMMNc  cNMMMWo                               //
//                                         cNMMMMK,                                                            .dWMMMMx.  .xMMMMX;                              //
//                                        '0MMMMWl                                                             :XMMMMK,    ,KMMMMk.                             //
//                                        dWMMMMk.                          ...'',,;;:::ccclllllllllllcccc::::c0MMMMWx'.....dWMMMNl       ..'.                  //
//                                       :XMMMMK;                 ...',,,;;:cclloooooooddddddxxkkkOO00KXXNNWWMMMMMMMMWXXKK00XWMMMMXOxxkkOkdl,.                  //
//                                      .OMMMMWo            ..'''''.....                             .....'',xWMMMMXkxkO00KXXNWMMMMWXOxl:'.                     //
//                                      oWMMMMO.        .',,,'..                                            .kMMMMWo     ....'xWMMMNl                           //
//                                     ;KMMMMX;      .,,,'.                                               .'xWMMMMO.          '0MMMMO.                          //
//                                    .kMMMMWo    .','.              .......                           ..'.:KMMMMX:            cNMMMWo                          //
//                                    lNMMMMO.  ','.          ...............'.                      .''. .xMMMMWd             .xMMMMK;                         //
//                                   ,0MMMMX:.',.         .''''..             ',.                  .,.    cNMMMM0'              ;KMMMMk.                        //
//                                  .xWMMMWx;;.         ',,'.                  ;,               .,;.     '0MMMMNc                oWMMMNc                        //
//                                  cNMMMMNd'        .,;'.                    .;'             .;:'      .dWMMMWx.                .OMMMM0'                       //
//                                 '0MMMMWk.       .,,.                       ;,            .:o;        :XMMMM0,                  :XMMMWd.                      //
//                                 dWMMMMK,       .'.                       .;'            ;dl.        .OMMMMNl                   .dWMMMX:                      //
//                                :XMMMMWx.                               ','.           ,xx'          oWMMMMk.                    '0MMMMO.                     //
//                               .OMMMMNdc,                            .','            'xOc.          ;XMMMMK;                      cNMMMWo                     //
//                               oWMMMMx..:,.                      ..'''.            .lKk'        ....kMMMMWo                       .kMMMMK;                    //
//                              ;KMMMMK,   ',,..              .......               ;0Kl.      .....c0WMMMMO.                        ;KMMMMx.                   //
//                             .kMMMMNl      ..'................                  .dN0,      .'.   .dWMMMMX:                          oWMMMNc                   //
//                             lNMMMMk.                                         :xKNx.     .'.  ..';OWMMMWd                           .OMMMM0'                  //
//                            ,0MMMMK;                                        .dNMNo.     ;l,......cNMMMM0'                            :NMMMWd.                 //
//                           .xWMMMWo                              .........'c0WNKd'....;dc'..    '0MMMMNc                             .dWMMMX:                 //
//                           :NMMMMk.                      .................dNMXc..    ;x:       .dWMMMWx.                              ,0MMMMO.                //
//                          .OMMMMX;                  ........            .xWMK;     .oKl        :NMMMM0'                                lNMMMWl                //
//                          oWMMMWo                 ....                 :0MWO'     'kWk.       .OMMMMNc                                 .kMMMMK,               //
//                         ;XMMMMO.                                    .dNMNx.     ;KMN:        oWMMMMx.                                  ;XMMMMx.              //
//                        .kMMMMX:                                    ;0WMXc.    .cXMMO.       ;XMMMMK;          ....                      oWMMMNc              //
//                        lWMMMWd.                                  .xNMWk'     lKNMMWl       .kMMMMWl      ......                         .OMMMM0'             //
//                       ,KMMMM0'                                 .cKMMKc.     cNMMMMX;       lWMMMMk. .......                              :NMMMWd             //
//                      .xMMMMNc                                .c0WMNx.      ,KMMMMM0'      ,KMMMMNo.....                                  .xWMMMX:            //
//                      cNMMMWd.                             .;xXWMNk,        :NMMMMMNd'....,kMMMMWd.                                        ,KMMMMk.           //
//                     '0MMMM0'                          .;lkXWMMNk;          .o0KXNNNXOdlc:kWMMMMO.                                          lWMMMWl           //
//                    .dWMMMMk:;;;;;;;;;;;;;;;;;;;::cldk0XWMMMMNx;              ...''...   '0MMMMN:                                           .kMMMMK,          //
//                    :NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo'                          .dWMMMWd.                                            ;XMMMMx.         //
//                   .kNNNWWNNNNNNNNNNNNNNNNNNNNNNWWNWMMMWXx;.                            :NMMMM0'                                              oWMMMNc         //
//          ..        .'''''''''''''''''''''''''''':dKNKx:.                               'ccccc'                                               .:cccc,         //
//          .,.                                 .:oxxl,.                                                                                                        //
//            ','.                         .';cclc,.                                                                                                            //
//              .'........       ......''',;,'.                                                                                                                 //
//                 ..',,,,,,,,,'''''''..                                                                                                                        //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ZFAtelier is ERC721Creator {
    constructor() ERC721Creator("Zanjani Fashion Atelier", "ZFAtelier") {}
}