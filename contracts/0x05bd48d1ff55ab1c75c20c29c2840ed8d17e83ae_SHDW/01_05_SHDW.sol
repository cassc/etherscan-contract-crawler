// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SHDW P3PL
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                             //
//                                                                                                                                             //
//    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    //                                                                                                                                 //    //
//    //                                                                                                                                 //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKKKKKKKKKKKKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWXOdoc'............'coddkXWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx:'.                     .;dooKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXk;.                             ;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.                               'dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.                                 ,kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO'                                   ;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;                                    ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'                                    ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                                    ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                                    ;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                ...   .'           .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.   .,....       .,:;:cc,           .'lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;    '3PC'        .shdw:.             'kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk'  .;::::.     .;c,..,p3;.           'kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.  .'.  ':,    .'.     pL,.          .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'                                   .;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'                                   ;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.                                 .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx.                             .;okXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:                             .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:                             .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc                             .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'                             'oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKc.                             :KWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:.                             ,dXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXd,                               .,okk0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0d,                                      .;:lx0KXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKo'.                                             ..'cd0NWMMMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xc,.                                                     .,ckNMMMMMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMWNKk:.                                                            .,ckXWMMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMMXx;..                                                                 .;kNMMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMMK:.                                                                      'kNMMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMKc.                                                                        ,0MMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMk.                                                                         ,0MMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMx.                                                                         .dNMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMMMx.                                                                          'kMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMWK:                                                                           .kMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMWd.                                                                           .kMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMWo.                                                                           .kMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMWl                                                                            .xMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMWl                                                                            .xMMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMWl                                                                            .oNMMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMMNl                                                                             .xWMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMNd.                                                                             .dWMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMNl.                                                                             .dWMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMNl.                                                                             ;0WMMMMMMMMMMMMMMMM     //    //
//    //    MMMMMMMMMMMMMMMMMMMMMXc                                                                             .xMMMMMMMMMMMMMMMMMM     //    //
//    //                                                                                                                                 //    //
//    //                                                                                                                                 //    //
//    //                                                                                                                                 //    //
//    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//                                                                                                                                             //
//                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SHDW is ERC1155Creator {
    constructor() ERC1155Creator("SHDW P3PL", "SHDW") {}
}