// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: United Glitched Nations (The Tweet)
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                 ,ccc::::::::;,.                            .'.         //
//          .,::;.                .xWMMMWWWWWX0kol:,''.....                   .l'         //
//         :ONMMWNOo,.   .         'clc:;;;,,:cdOOkl.......                   .l'         //
//        lNMMMMMMMMN0c.  .                  .;kMMWl    'oxdl:.               .c'         //
//       ,KMMMMMMMMMMMWd..;.     .ckOOd:..   .'xMMNc   :KMMMMWXk:.     ,dxdc. .'.         //
//       :XMMWWWMMMMMMMX:.lo.    oNMMMMWO:.   .oWMK,  'OMMMMMMMMWOc.  ,KMMMWO' .          //
//       ,KMMWKxolodkOO0c :Kl   .kMMMMMMK:    .lWMO.  cNNKOxxddxxddl'.dWMMMMMOl;          //
//       .dWMMMXkl'.   .  ,KK;   oNMMMMMX:     cNWo   ;XWN0koc;..    .kMMMMMMKo;.         //
//        .oXMMMMMNOl,.   .OWk.   ,lOXKkc.     ;XK;   .xWMMMMMWX0:   .dWMMMMX: .'.        //
//          .coxkkkkkxc.  .xMWd.     ..        'Ox.    .xNMMMMMMWd    :XMMMK:  .ox.       //
//                         cNM0'               .o:      .:xXWMMMNc     ;x0x,    .,.       //
//     .'.                 .dd,                 ..         .,:clc,.                       //
//     ;x'      .';cc;'.                                       'kXx.                      //
//     cx,.';ldOXNWMMWN0d:.                                    lNWo   .                   //
//      ;kKNWMMMMMMMMMMMMWKc.   .  .'.           .,'     :xdllcdKO'  .dx;                 //
//      .kMMMMMMMMMMMMMMMMMWx..l0Oo,oOd;.       ;ONo    :X0:'l00O:    :XNx.               //
//       cNMMMMMMMMMMMMMMMMMWl'kMMK;.c0N0c.    .xMWl   .kMO' .xXo.    .dWWo.              //
//       .xWMMMMMMMMMMMMMMMMMx.oNKc   .lKW0l. .:XMN:   .dNW0l;;,       ,KMO. .';;.        //
//     .ldkOOXWMMMMMMMMMMMMW0; .:'      .oKN0l:kWM0,    .,codxdl.      ,KMk. :XWK;        //
//      ;KNl..;cok0KXXXXXKOl.  .c;        .ld' .dXk.     'oxxc;,.      lNWd  ,0MNc        //
//       ;0K;      .......     :XNd.       'c'   'c,.   .xWMO'        ,0MNc  .xMWd        //
//        ,Ox.                .kMMWk.     .xWKOo..xN0o'  cNMNo.      .dWMX;   cNMO.       //
//         'xc                cNMMMWk.    cNMMMWOoKMMMNkc,c0WWOlclo' ,0MMNx:,,oNMX;       //
//          .l,              .xWMWWWk.   ;KMMMMMXooXMMMMWk'.lKWMMMk. oWMMMMWWNWMMWd.      //
//           .;.              .;::;,.   ,0MMMMMWd. ;0MWKd,   'xNMX: .cddddddxk0XNMK,      //
//                                     .kXX0OOOo.   .c:.      .;o:             .,::.      //
//                                     .....                                              //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract UGNT is ERC721Creator {
    constructor() ERC721Creator("United Glitched Nations (The Tweet)", "UGNT") {}
}