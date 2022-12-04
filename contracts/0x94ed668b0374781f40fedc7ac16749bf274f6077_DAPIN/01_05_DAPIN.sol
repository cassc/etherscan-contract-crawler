// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dead Avatar Project Inventory
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                              .';:cclllllllcccc:;,.                                         //
//                                          .:oOXNWMMMMMMMMMMMMMMMMWXOo,                                      //
//                                       .cxXWMMMMMMMMMMMMMMMMMMMMMMMMMNOc.                                   //
//                                    .;xXMMMMMMMMMMMMMMMMMXxookkOWKkxoddO0c                                  //
//                                   ,OWMMMMMMMMMMMMMMMMMMMNO;cKl,d:,,.;;xWNc                                 //
//                                  :XMMMMMMMMMMMMMMMWOdodddo,;d;,o:'...';od:.                                //
//                                 .OMMMMMMMMMMMMMMMMWKl,,:xOOOOOOOOOOOOO:                                    //
//                                 ;XMMMMMMMMMMMMMMMMMMWWKolkNMMMMMMMMMMMo                                    //
//                                 :NMMMMMMMMMMMMMMMMMMMMMWd'okkko::oXMMMo                                    //
//                                ,OWMMMMMMMMMMMMMMMMMMMMMMxc0WWX:  .OMMMo                                    //
//                              .oXMMMMWWMMMMMMMWKxxO0KNWWMxcKMMNc  .OMMMo                                    //
//                              .kWWOc:,:OWMMMMNl.   ..,:xWxcKMMWOooxXMMMo                                    //
//                               '0K,    .kMMMMK,        .ddc0MMMMMMMMMMMo                                    //
//                                ;O:    'OMMMMO.         .;:x00000000000c                                    //
//                                .dl   ;0WMMMMO.         .:cOXXXXXXXXXXXo                                    //
//                                :Ko  .xkxNMMMWO,        col0MMMNXXXWMMMx.                                   //
//                               .kMN0k0K; ;OWMMMXd:;,':okNkl0MMMKkxONMMMx.                                   //
//                                ;KMMMMK,  .kMMMMMMMWWWMMMOl0MMMMMMMMMMMx.                                   //
//                                 'odOWXoxko0MMMMMMMMMNXXNOl0MMWKkkONMMMx.                                   //
//                                   .dWMWWMMMMMMMMMMMXl..'.;KMMWl  .kMMMx.                                   //
//                                   ,KMMMMMMMMMMMWNKKO'    ,KMMWc  .kMMMx.                                   //
//                                   .;ookdxkkxxxdc;'.:'    .d0OOl,,;dKWMx.                                   //
//                                   .. .. ...........':;.  'OWWWWWWWKOkKd.                                   //
//                                   ..... .......';;:dXNd. '0MMXxodokNXOc                                    //
//                                    .'...';.;:lxkKXWWMMWK;'0MMx.   ,KMWo                                    //
//                                     :OKOOK0XWWMMMMMMMMMNc'0MM0:,,,oXMMd                                    //
//                                    .oNMMMMMMMMMMMMMWKOxl.'0MMMWWWWWMMMd                                    //
//                                    '0MMMMMMMMMMMNOo,.    '0MMXxooooooo,                                    //
//                                     ,dOKXWMMMMNx,        '0MMx.                                            //
//                                        ..';:cl'          .OWWx.                                            //
//                                                           .,,.                                             //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DAPIN is ERC1155Creator {
    constructor() ERC1155Creator("Dead Avatar Project Inventory", "DAPIN") {}
}