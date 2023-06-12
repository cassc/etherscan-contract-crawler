// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ameruverse Digital Automated Machines
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                 ..                          ..                                                 //
//                                             .:dO00Okl'                  'lxO00Oxc.                                             //
//                                            :KWMMMMMMMNd.              .oXMMMMWMMMKc                                            //
//                                           ;XMMNx:;oKMMWo              lWMMXd;:xNMMN:                                           //
//                                           cWMMK,  .xMMMO.            .xMMMk.  '0MMMo                                           //
//                                           '0MMWKdoONMMMO.            .kMMMWOod0WMMK,                                           //
//                                            'xXMMMMMMMMMXdlllllllllllldKMMMMMMMMMNx,                                            //
//                                              .:oddoOWMMMMMMMMMMMMMMMMMMMMM0dddo:'                                              //
//                                                .'''dWMMXkddddddddddddkXMMMx'''..                                               //
//                                             ,d0XNNNNMMMO.            .kMMMWNNNX0d;                                             //
//                                           .oNMMWNXWMMMMO.            .kMMMMWXNWMMNd.                                           //
//                                           :NMMXo'.:0MMMO.            .kMMM0:..lXMMWl                                           //
//                                           cWMMX:  .kMMM0,...      ...'OMMMO'  ;KMMWl                                           //
//                                           .xWMMN0OKWMMMWKKKO,    'kK0KNMMMWXOOXMMWO.                                           //
//                                            .cONMMMMWWWWWMMMN:    ;XMMMWWWWWMMMMN0l.                                            //
//                                               '"cc"'    XMMWKkkkkKWMMX    '"cc"'                                               //
//                                                         XMMMMMMMMMMMMX                                                         //
//                                                         ;ccl0MMMM0lcc;                                                         //
//                                                            'kMMMMk,                                                            //
//                           .;ok0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXWMMMMWXXXXXXXXXXXXXXXXXXXXXXXXXXK0kd:.                             //
//                         .c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo.                           //
//                        .kWMMMMWXK000KKKK0000000000000000000000000K00000000000000000KK0K00K0KXWMMMMM0,                          //
//                      'cOWMMMWO:.                                                            .;xNMMMMKo,.                       //
//                   ,oONMMMMMMO.      .,:llooooooooooooooooooooooooooooooooooooooooooolc;'.     .dWMMMMMWKx:.                    //
//                .cOWMMMMMMMMMd.   .:xKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0o'    lWMMMMMMMMWKd'                  //
//              .:0WMMMMWWWMMMMd.  ;OWMMMNKOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0XWMMMXo.  cWMMMMNWMMMMMXd.                //
//             .xWMMMMNk:oNMMMMx. :XMMMKl'                                              .:kNMMWx. cWMMMWx;dXMMMMW0;               //
//            ,OMMMMWO;  ;XMMMMx. OMMM0,          .                            .          .oNMMWc cWMMMWo  'xNMMMMXc              //
//           'OMMMMWd.   ;XMMMMx. XMMMo       .;x00Ox;                      ;x000x:.       ,KMMMd cWMMMWl    :KMMMMX:             //
//          .dWMMMWd.    :XMMMMx. XMMMo      .xWMMMMMNd.                  .dNMMMMMWx.      '0MMMx cWMMMWo     :XMMMM0'            //
//          ,KMMMMO.     ;XMMMMx. XMMMo      oWMMMMMMMWo                  lWMMMMMMMWo      '0MMMx cWMMMMo      oWMMMWo            //
//          lWMMMMo      ;XMMMMx. XMMMo     '0MMMMMMMMMO.                .OMMMMMMMMM0'     '0MMMx cWMMMMo      ;KMMMMk.           //
//          oMMMMWc      ;XMMMMx. XMMMo     ,KMMMMMMMMMK,                ,KMMMMMMMMMX;     '0MMMx cWMMMMo      '0MMMMO.           //
//          lWMMMWl      ;XMMMMx. XMMMo     '0MMMMMMMMMO'                .OMMMMMMMMM0'     '0MMMx cWMMMMo      ,KMMMMk.           //
//          ;XMMMMk.     :XMMMMx. XMMMo     .dWMMMMMMMWo                  oWMMMMMMMWd.     '0MMMx cWMMMMo      lWMMMWo            //
//          .xMMMMNo     ;XMMMMx. XMMMo      .kWMMMMMWx.                  .xWMMMMMWk.      '0MMMx cWMMMWl     ;KMMMMK,            //
//           ,0MMMMNo.   :NMMMMx. XMMMo       .ckKXKkc.                    .:kKXKkc.       ,KMMMd cWMMMMo    ;0MMMMNl             //
//            ;KMMMMWk'  ;XMMMMx. OMMM0,         ...                          ...         .oWMMWl cWMMMMo  .oXMMMMNo.             //
//             ,OWMMMMXx,lNMMMMx. :XMMMKo,.                                            ..:kNMMWx. lWMMMWd'l0WMMMMXc               //
//              .lXMMMMMNNWMMMMx.  ,OWMMMNK0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0XWMMMXo.  lWMMMMNXMMMMMNk'                //
//                .oKWMMMMMMMMMx.   .:xKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNO:.    lWMMMMMMMMMNx;                  //
//                  .:xXWMMMMMMk.      'ooooooooooooooooooooooooooooooooooooooooooooooooo'       oMMMMMMWXOl'                     //
//                     .;oKMMMMWx,.                                                            .'oXMMMMXd:'                       //
//                        'OWMMMMN0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0NMMMMMX:                          //
//                         .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx'                           //
//                           .cx0XNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNX0kl'                             //
//                               .''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''..                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                            AMERUVERSE DIGITAL AUTOMATED MACHINES                                               //
//                                                                                                                                //
//                                                      Genesis A Series                                                          //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ADAM is ERC721Creator {
    constructor() ERC721Creator("Ameruverse Digital Automated Machines", "ADAM") {}
}