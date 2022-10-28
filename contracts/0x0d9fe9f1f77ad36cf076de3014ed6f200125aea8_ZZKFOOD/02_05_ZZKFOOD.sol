// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Zouzoukwa · Food
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNNXNNNWWMMMMMWOlccccccclccllxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOdoc:;,'.....',;:ccldl.             oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWXOo:'.                                   lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMXkc.                                       cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWKo'                                          ;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMKo.                                              ,xXMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWk'                    .....                         ,xXMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNd.              .,coxO0KKKKK0x,                        ;0MMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWx.            .;dKNMMMMMMMMMMWx.                       'dXMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMM0'            'kNMMMMMMMMMMMMWk.                     .;xXMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWo            .OWMMMMMMMMMMMMM0,             .c;    .cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMX:            :NMMMMMMMMMMMMMK;             .dWXl.'oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMX:            ;KMMMMMMMMMMMMX:             .dNMMWXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWl             :KWMMMMMMMMMNl             .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMO.             .:x0XNWWMMNo.             :O0OOkkkkOO0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWd.                .';::c;.              ...        ..',cokXWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNd.                                                       .:dKWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWO;                                                         .lKWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNx;.                                                        .xNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNOl,.                                                      .dNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMN0dc,..                    .,:clooooolc:,.               .kWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kxoc.            'lkXWMMMMMMMMMMMNKx:.             :XMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.           'OWWMMMMMMMMMMMMMMMMWk'            'OMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.           .kWMMMMMMMMMMMMMMMMMMMWd            .OMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'           .xWMMMMMMMMMMMMMMMMMMMMWo            ,KMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,           .dWMMMMMMMMMMMMMMMMMMMMWk.            oNMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;           .oXX0Okxdolllllodxk0KNWXo.            ;KMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc            .,,..               .';'             ;0MMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                                                 cKMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.                                               'xNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWx.                                              .oXMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWk.                                               .lXMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMO'                         ..                       cXMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMM0,                ..;coxkOO0000Okdl:'                 cXMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMX:              .;d0XWMMMMMMMMMMMMMMWNOl.              .dWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMXc             .c0WMMMMMMMMMMMMMMMMMMMMMWKl.             ,0MMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNo.            'kWMMMMMMMMMMMMMMMMMMMMMMMMMWx.            .dWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWd.            'OWMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.            cNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWx.            .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,            ;KMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWO.            .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:            ,KMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMM0,            .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc            ;XMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMK;             lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;            cNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMXc             cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'           .dWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNl             ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.           'OMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNo.            ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;            cNMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWx.            'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.           .kMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWk.            .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,            cNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMO'            .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc            .OMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMX:            .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.           .oNMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNxllllllllllllxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOolllllllllllxXMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ZZKFOOD is ERC721Creator {
    constructor() ERC721Creator(unicode"Zouzoukwa · Food", "ZZKFOOD") {}
}