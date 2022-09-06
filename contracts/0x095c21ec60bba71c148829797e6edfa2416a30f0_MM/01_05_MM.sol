// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MaximMoyen
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                          ..                                    //
//                             .,,.       'lc'.                                .,.        .o0x,.                                  //
//                           .cOWNx.   .lxdxxxk;                             .c0WNklc,  .dXMMMNO;                                 //
//                           oMMMMWO' 'OWMW0xc,.                             .x0OXMWMK;'0MMMMMNl                                  //
//                           ,0WMMMMKkXMMMMM0'                                 ..kMMMMK0WMMMMX:                                   //
//                            .cKMMMMMMMMMWO,                                   .kMMMMMMMMMWO,                                    //
//                              'kWMMMMMMWx.                                     ;kXMMMMMMWx.                                     //
//                               .OWMMMMMO.                                       .oWMMMMMK,                                      //
//                              .dNMMMMMMXl.                                     .lXMMMMMMWO:.                                    //
//                             ,OWMMMMMMMMWx.                                    :XMMMMMMMMMWO;                                   //
//                            .xMMMMMNXWMMMW0;                                  ;KMMMMK0NMMMMWl                                   //
//                            .kMMMMNl'kWMMMMX:                               .lKMMMW0,.oKWMMWd.                                  //
//      ..                   .kWMMMK:  'cxXMWK:                               'kXNMWk.   'xKK0l.                                  //
//      'xd,.                .:kXWO'      ':,,.                                ..,lc.     ....                                    //
//      .kWXc.                  ':'                                                                                               //
//       '0N0xxc                                                                                                      ..          //
//        ,0XkO0;                                                                                                   'ox;'l;       //
//         ,OkcxXx'                                                                                            ..'cxdc,.l0:       //
//          cXO:oKKd.                                                                                      .. .oK0d;.,:od:.       //
//          .xKl.,xXO;.                                                                              ,lo;..'cdkOo,.,x0kc.         //
//          .lNXl..;ON0dc,.                                                               . .       .oXMklxOkd;'.,kNNx'           //
//           .dWNk' .;xKNN0Odc,.    ':,'''''.               .....  .''.  ...;,..,;:llxOOOOkl;'''';:cok00dll,...'oXWO,             //
//            ,kNWd.   .'lxOXN0kk000NWWNNNNNK0kxdkOOOOOOO0OO0XXX0O0KNNKOO00KNNXXNWWWWWMMMWNX00KOxkkdl:'..  ..'dXMNd.              //
//            .xXWWO;    ....''':looookOxxkxOKXNXXKKNWNWWWWNNNWWNXXNNXXXXXXWWNNWNXXXXKkkdllcclc,.. .....'. cOXMMXc                //
//             'dNMNKd.        ..     .'. .  ....'..',;;;;c:',lo;'.,,'.....,:;,,,'.... ..    ...  ......;lkNMMWk'                 //
//              ;XWKk00k,             .'.  ..        ..   .. .lo.             .      .       ...  . .;dO0xkNMWk.                  //
//               :KXOKNNKx:..      .. .xk.  .             ..  .;'             .                .':dkOklxd,xMWO.                   //
//                dWWNk::kXOdo'   ..  .xK,    ..           .   ..                           .:oxOko:.  ;0OKMN:                    //
//                ;XMW0:  'c0NOl'.    .ONl.   .                           .  .       .'',cdxkko:'      cWOkWx.                    //
//                .kMMNl    'okOkddolldKX:                                   ...,cldOKNNKxc;...        cWOkXc                     //
//                 oWMO.       .:ONMMMWWNx:.    ..          .....      .,;;:coOKWMN0Ok0MXc;,           ,0Okd.                     //
//                 cNNc         .oWMMMMMMWNXOl;',,.';'''.';:l:;ldoooox0XXWMWNK0xll:.. ,KNd;. ..         ,ONo                      //
//                 ,KWl;c.       dMMMMMNdokkk0XKKXXNWWNNNXNWWXXWMMWXK0Okdxo;'..        lNO, 'k:         .xWx.                     //
//                 .xWdlx.       oWMMMMXl..  ..;cclodoc:xNN0XKooXX0c..                 '0Nc .'.          lWX:                     //
//                  ;Xx:o,       .kWMMMMXo.             ,KWXN0,;Xd.                    .dNO'             lXO;                     //
//                  .kl.;.        .xWMMMWk.             .OMMMO.cWl                      .ld;.            .:c.                     //
//                  ,d'.l,         .xWMWx'              .kMMMO'oWl                       ':.              .c'                     //
//                  ,: :Xl          ,KMO,'.             ,KMWXc.xWl                       ,l.              .d,                     //
//                   ..,Kx.         .OX;;o.             .kWWd. cNd.                       .  ...          ,d'                     //
//                      :x,         ;Ko cx.              oWMK, .kOc.                          .           ':.                     //
//                       ..         ,k; c0,              ,0Nd. .dOl.                      ..              .'                      //
//                       ;:         o0, :k'               o0'  .dOl'                      ll              ';                      //
//                       ;c         ;k: .c,               ,c.   lKx,                      :o. ..                                  //
//                       .;.        .oc  c;                .    :Ok;                      ,l. ..                                  //
//                        ,.         'l. ..                     .:o'                      .:.                                     //
//                       .dc          :,.;'                      ':.                       .                                      //
//                        lc          ::.c,                      .'.                                                              //
//                        ;;          .,.:;                     .d0:                                                              //
//                        ..           . ll                     .dK:                                                              //
//                                       dd                      .,.                                                              //
//                                       :k'                                                                                      //
//                         ..            .xl                                                    .                                 //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MM is ERC721Creator {
    constructor() ERC721Creator("MaximMoyen", "MM") {}
}