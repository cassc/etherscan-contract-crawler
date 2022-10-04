// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Banshee
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                 .''.           //
//                                                                                                               .oOKKOo.         //
//                                                                                                              ,0MMMMMMO.        //
//                          ..''.                                                                              '0MMWXNMMWo        //
//                      .;lkKNWN0:                                                                .'..        .xWMMO;xMMMk.       //
//                   .:xKWMMMMMMMO.                               .;odl'                        .dXNN0c       lNMMX;.kMMWd        //
//                .;xXWMMMMNNMMMMk.                              lXNMMMK,    'ol.              .OWMMMMO'     .OMMMx.cNMMXc        //
//              .l0WMMMWXxc;kMMMWo                              .OMMMMMMx.  .xMWo             .xWMMMMM0'     :NMMMkdXMMMWXd.      //
//            'dXMMMMNk:.  cNMMM0'                              ,KMMMMMM0'  .xMMx. .:dxo,     cNMMMMMMO.     oMMMMMMMWNWMMMx.     //
//          .dXMMMWKo'    :XMMMX:                               '0MMMMMMK,  .xMM0''OWMMMX;   .OMMMMMMMd     .xMMMMMMXooXMMMK,     //
//        .cKMMMW0c.     :KMMMNl                                .xWMMMMM0'  .xMMXx0MMMMMMx.  :NMMMMMMN:     .xMMMMNx..xMMMMX;     //
//       .dNMMMXl.      cXMMMNo.                    .:ll;.       ;kKMMMMk.  .xMMMMMMMMMMM0'  oMMMMMMMO.      dMMMMX: :XMMMM0'     //
//      .oWMMM0,      .oNMMMNl          'lo:.      ;0WMMWx.      .;kMMMMO.  .xMMMMMMMMMMMX: .xMMMMMMWl      .kMMMMMKkKMMMMNl      //
//      ;XMMMK,      .kWMMMXc          ;KMMW0dd,  :XMMMMMX:      .lOMMMMNo. .xMMMMMMMMMMMWo  oWMMMMM0,     .oNMMMMMMMMMMMNo.      //
//      dMMMWo      ;0MMMMM0oc,       .xWMMMMMMo ;XMMMMMMWo      lXNMMMMMWk..xMMMMMMMMMMMMO. ;XMMMMMx.    .xNMMMWWWMMMMNO;        //
//     .kMMMN:    .oNMMMMMMMMMNl   ,cd0NMMMMMMWl;KMMMMMMMMx.    ;KMMMMMMMMM0lOMMMMMMMMMMMMX; lNMMMMMXklccxXMMMMXo',cll:'          //
//     .xMMMNc   ,OWMMMMMMMMMMM0:cONWKXMMMMMMMNOKMMMMMMMMMO.   ,0MMMMKldNMMMWWMMMMMMKxKMMMMKONMMMMMMMMMMMMMMMWO;                  //
//      oWMMMx..lXMMMMMMMMMMMMMWNWNk;;0MMMMMMMMMMMMMKKWMMMK,  ,0MMMMX:  ;KMMMMMMMMMWd.;KMMMMMMMMNOxOXWMMMMNKd;.                   //
//      ,KMMMXxkWMMMMMMMMMMMMMMMMKc .dWMMMWNWMMMMMMK:lWMMMX; ,0MMMMWx,;cxXMMMMMMMMMX;  'xKWMWNKd,   .,:::;'.                      //
//       oWMMMMMMMMMMMWNWMMMMMMM0, .oNMMMMOkWMMMMMNc lWMMMX:'0MMMMMWNNWMMMMMMMMMMMMx.    .,;;'.                                   //
//       .kMMMMMMMMMMKx0WMMMMMM0' .dNMMMMNoxMMMMMNo  oWMMMKcxMMMMMMMMMMMMNKkldXMMW0,                                              //
//        :NMMMMMMMXdcOWMMMMMMX: ,OWMMMMM0:xMMMMWd.  lWMMMKcdNKkdkOO0Oxo:'.   'oo:.                                               //
//        cNMMMMMMO;:0MMMMMMMMOcdNMMMMMMMx.oWMMWx.   ,0MMM0'...                                                                   //
//        lNMMMMMM0xXMMMMKxKMMWWMW0kXMMMWo .:oo;.     ,x0k;                                                                       //
//         ,loONMMMMMMMWO' 'okOko;.'0MMMNc              .                                                                         //
//             lNMMMMMNd.          .xWMMNc                                                                                        //
//             :XMMMMXc             .xXNk'                                                                                        //
//             oWMMNk,                .'.                                                                                         //
//             'kX0l.                                                                                                             //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LUA is ERC721Creator {
    constructor() ERC721Creator("Banshee", "LUA") {}
}