// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: R.E.M
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                             ..                                                                             //
//                 ,c:.      .;O0;                                                                            //
//                '0MMXkdxxkk0NMX;                                                                            //
//                ,KMMMMWWNNWNNNXo.                                                                           //
//               .xWMMMWXKXWNXNNXXk'                                                                          //
//              .kWMMMMN0KN0xxKWWWKo.                                                                         //
//             .xWMMMMMNXWXKOokXWMKOc                                                                         //
//             cNMMMMMMWWMWWMMWWMWXXd.                                                                        //
//            .kMMMMMMMMMMMMMMMMMXO0Kc.........'...;:'....;;.                                                 //
//            :NMMMMMMMMMMMMMMMWNN0xxddk0KXXXXXXl.dNk'.;oOKl. .;l,.                                           //
//           .OMMMMMMMMMMMMMMMMWWNXkookKNWWWWWWXccNO,'o0Xk,  'oo,..cc.                                        //
//           :NMMMMMMMMMMMMMMMMMXKKxox0NWWWWWWMNxONo;kO:.. 'dk;.,dko:lc.                     .lxOxc.          //
//           dMMMMMMMMMMMMMMMMWX0kkkOKNWWWWMMMMWXNXx00;..,dK0llOXOcoOkclc.                  cXWKOKWK:         //
//          .kMMMMMMMMMMMMMMMWXXX00KNWMWWMMMMMMMWWNNNkodkKWKkKWN00XN00XWWk.                cNXc. .lOc         //
//          .OMMMMMMMMMMMMMMMMWWXKKXNWMMMMMMMMMMMMMWX0NMMMNXWMMNNMMNNMMMMM0,              .xMx.               //
//          .OMMMMMMMMMMMMMMMWNNNNNNNMMMMMMMMMMMMMMWNNMMMMWWMMMMMMMMMMMMWNW0'              dMk.               //
//          '0MMMMMMMMMMMMMMMMWWWWWNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXWWx.             ;XNc               //
//          '0MMMMMMMMMMMMMMMMWWWMWNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXWMMNc              oWK,              //
//          .OMMMMMMMMMMMMMMMMMWMMWNWMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMWk:xWMMK,             .dNO'             //
//           dMMMMMMMMMMMMMMMMMMMMNXWMMMMMMMMMMMMMMMMMWWWWWMMMMMMMMMMMO' .kWMMO'             .lXO'            //
//           ;XMMMMMMMMMMMMMMMMMMMX0NMMMMMMMMMMMMMMMMMWNNNWWWMMMMMMMMWl   .kWMWO'              cK0,           //
//           .xMMMMMMMMMMMMMMMMMMMXkKMMMMMMMWNXKOxoooONNXNWWMMMMMMMMMMd    .kWMM0;              ;0K;          //
//            :NMMMMMMMMMMMMMMMMMMWKo;;:cc::,'..      lXNWWMMMMMMMMMMMO.    .kWMMK:              'OXl.        //
//            'OMMMMMMWOccod0WMMMMMWd.                ;XMMMMMMMMMMMMMMX:     .dNMMXl.             ,KNo.       //
//             dMMMMMMM0'   ;XMMMMMMd.                ,KMMMMMMMMMMMMMMMO.      cKMMNx.             dWNc       //
//             :NMMMMMMWc   ;XMMMMMNc                 ,KMMMMMMMMMMMMMMMWk.      'xNMMKl.           lWMd.      //
//             .OMMMMMMWl   :NMMMMM0'                 '0MMMMMMMMMMMMMMMMM0;       ;ONMWKo,.      .oXMNc       //
//              lNMMMMMMo   :NMMMMWo                  .OMMMMMMXdxNMMMMMMMMNx.      .;dKWMNKxocccdKWMXc        //
//              .kWMMMMWc   cWMMMM0'                  .xMMMMMMx. ;kNMMMMMMMWx.        .,cdk0KXNXK0kl.         //
//               ,0MMMMX;   oWMMMNc                    oWMMMMWl    'lONMMMMM0'             .......            //
//                lWMMMO.  .OMMMMk.                    cXWMMMWl       ;OWMMMk.                                //
//                ;XMMMk.  ;XMMMWc                     dWMMMMX:        '0MMMd                                 //
//                .OMMMk.  :NMMMk.                    ;XMMMMK;         .kMMWc                                 //
//                 dMMMK,  lWMMK;                    ,0MMMW0,          ;KMMK,                                 //
//                 cWMMN: .xMMWl              ...',:xXMWN0c.        .cxKWMMx.                                 //
//               .:0WMMWc.dNMMX;            ;OKKKNWWWKd;'.        ;OXWWWWWK:                                  //
//             .:OWMMNKXkkWMMMX;           .oKKKKK0kl.            .;:;',,'.                                   //
//           ,okXNNW0;.dddNWWWK,             .'...                                                            //
//           'clllkd.  .,okOdxOo'                                                                             //
//              .',     ;c;o,.:;'.                                                                            //
//                      .  .                                                                                  //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract REM is ERC1155Creator {
    constructor() ERC1155Creator("R.E.M", "REM") {}
}