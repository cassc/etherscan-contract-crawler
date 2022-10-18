// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Honorary Darcels
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                //
//                                                                                                                //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    //                                                                                                    //    //
//    //                                                                                                    //    //
//    //    ////////////////////////////////////////////////////////////////////////////////////////////    //    //
//    //    //                                                                                        //    //    //
//    //    //                                                                                        //    //    //
//    //    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0dl;'..      ..';ld0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMMMMMMMMMMMMMMMMMXkc'.                  .'ckXMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMMMMMMMMMMMMMMWKd'                          'dKWMMMMMMMMMMMMMMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMMMMMMMMMMMMMKo.                              .oKMMMMMMMMMMMMMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMMMMMMMMMMMNx'                                  'xNMMMMMMMMMMMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMMMMMMMMMW0:                                      :0WMMMMMMMMMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMMMMMMMMNx.                                        .xNMMMMMMMMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMMMMMMMXl.                                          .lXMMMMMMMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMMMMMMK:                                              :KMMMMMMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMMMMM0;                .';:llooooll:;'.                ;0MMMMMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMMMW0,             .:okKNWMMMMMMMMMMWNKko:.             ,0WMMMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMMM0;           .:xXWMMMMMMMMMMMMMMMMMMMMWXx:.           ;0MMMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMMX:          .l0WMMMMMMMMMMMMMMMMMMMMMMMMMMW0l.          :XMMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMNl          :0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:          lNMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMWx.        .dNMMMMMMMMMMMWNKOkkkkOKNWMMMMMMMMMMMNd.        .xWMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMM0,        .xWMMMMMMMMMWKd:..      ..:dKWMMMMMMMMMWx.        ,0MMMMMMMMM    //    //    //
//    //    //    MMMMMMMMNl        .oNMMMMMMMMMXo.              .oXMMMMMMMMMNo.        oNMMMMMMMM    //    //    //
//    //    //    MMMMMMMM0'        ;KMMMMMMMMM0;                  ;0MMMMMMMMMK;        '0MMMMMMMM    //    //    //
//    //    //    MMMMMMMWo         oWMMMMMMMMX:                    :XMMMMMMMMWo         oWMMMMMMM    //    //    //
//    //    //    MMMMMMMK;        .xMMMMMMMMMO.                    .OMMMMMMMMMx.        ;KMMMMMMM    //    //    //
//    //    //    MMMMMMMO.        .xMMMMMMMMMk.                    .kMMMMMMMMMx.        .OMMMMMMM    //    //    //
//    //    //    MMMMMMMd.         dWMMMMMMMMK;                    ;KMMMMMMMMWd         .xMMMMMMM    //    //    //
//    //    //    MMMMMMMd          ;XMMMMMMMMWk'                  'kWMMMMMMMMX;          dMMMMMMM    //    //    //
//    //    //    MMMMMMWo          .dWMMMMMMMMW0:.              .:0WMMMMMMMMWd.          dWMMMMMM    //    //    //
//    //    //    MMMMMMMd           .kWMMMMMMMMMNOl'.        .'lONMMMMMMMMMWk.           dMMMMMMM    //    //    //
//    //    //    MMMMMMMx.           'kWMMMMMMMMMMWN0kdoooodk0NWMMMMMMMMMMWk.           .xMMMMMMM    //    //    //
//    //    //    MMMMMMMO.            .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.            .OMMMMMMM    //    //    //
//    //    //    MMMMMMMXc              'xXWMMMMMMMMMMMMMMMMMMMMMMMMMMWXx'              cXMMMMMMM    //    //    //
//    //    //    MMMMMMMMk.               'o0NMMMMMMMMMMMMMMMMMMMMMMN0o'               .kMMMMMMMM    //    //    //
//    //    //    MMMMMMMMNo.                .,lkKNWMMMMMMMMMMMMWNKkl,.                .oNMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMXc                    .':lodxkkkkxdol:'.                    cXMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMXc                                                        cXMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMMXo.                                                    .oXMMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMMMWk,                                                  ,kWMMMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMMMMMXo.                 ,:.      .:,                 .oXMMMMMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMMMMMMWKo'               ;kOo::::oOk;               'oKWMMMMMMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMMMMMMMMWXx;.             .;loddol,.             .;xXWMMMMMMMMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMMMMMMMMMMMW0d:.                              .:d0WMMMMMMMMMMMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMMMMMMMMMMMMMMWXko:'.                    .':okXWMMMMMMMMMMMMMMMMMMMMMMM    //    //    //
//    //    //    MMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdc,..          ..,cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //    //    //
//    //    //                                                                                        //    //    //
//    //    //                                                                                        //    //    //
//    //    ////////////////////////////////////////////////////////////////////////////////////////////    //    //
//    //                                                                                                    //    //
//    //                                                                                                    //    //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//                                                                                                                //
//                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HonorDD is ERC721Creator {
    constructor() ERC721Creator("Honorary Darcels", "HonorDD") {}
}