// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: What I Thought I Knew
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                     .,:::'.            .,cc:,.                               //
//                                                                                                    .:oxxxxl,.         .cdkkkxo;.                             //
//                                                                                                    'oxkkkkko'         'lxkkkkkd;.                            //
//                                            .',,..                    .',,'.                        ,okkkkkkd;.        .:xkkkkkxl.                            //
//                                          .,ldxxo;.                 .;oxxxdl,.                      ,okkkkkkx:.         ,dkkkkkkd:.                           //
//                                         .:dxkkkx:.                .:dxkkkkkd:.                     ,okkkkkkxc.         ,okkkkkkxc.                           //
//                                        .cxkkkkkd;.                .lkkkkkkkkd;..                   'lkkkkkkxl.         .lxkkkkkxl.                           //
//                 .';:;'.               .;dkkkkkko'                .:dkkkkkkkkxl;.                   .lxkkkkkkl'         .:xkkkkkko'                           //
//                'cdkkkxo;.             'lxkkkkkxc.                'okkkkkkkkkkxoc.                  .:xkkkkkkd;.         ,dkkkkkkd;.    .......               //
//               .cxkkkkkkd;.            'okkkkkkd;.               .;dkkkkkkkkkkkxd;.                  'okkkkkkxc.         .cxOkkkkxl;',:coodddoo:.             //
//               .:xkkkkkkkd;.           ,dkkkkkkl'                .cxOkkkkkkkkkkkxl'                  .okkkkkkxc.         .;dkkkkkkxxxxkkkkkkkkxo'             //
//                ,dkkkkkkkkd;.         .:xkkkkkx:.               .,okkkkkkkkkkkkkkxl.                 .okkkkkkxl'         .:dkkkkkkkkkkkkkkkkkxl,.             //
//                ,okkkkkkkkkd;.        .cxkkkkkx;.               .:xkkkkkkkkkkkkkkkxc.                .lxkkkkkkl'    ...,cdxkkkkkkkkkkkkkxxdl:'.               //
//                'okkkkkkkkkkd:.       'lkkkkkkd;.               .cxkkkkxxdxkkkkkkkkd,                .:xkkkkkkl,..';coxkkkkkkkkkkkkkxol:,...                  //
//                .lxkkkkkkkkkkxc.      'okkkkkkd;               .:dkkkkkxo::dkkkkkkkko;..             .;dkkkkkkxoldxxkkkkkkkkkkkkkkko;..                       //
//                .lxkkkkkkkkkkkxl'     'lkkkkkkd;.              .lxkkkkkx:..cxkkkkkkkkdlcc;'.         .;dkkkkkkkkkkkkkkkkkkkkkkkkkkko,.                        //
//                .cxkkkkkkkxkkkkxl'    .lkkkkkkd;.              ,dkkkkkkd;..,okkkkkkkkkkkkxd;.        .cxkkkkkkkkkkkkkkkxdl:cokkkkkkd;.                        //
//                .:xkkkkkkkkkkkkkko,. .,okkkkkkx;.             .cxkkkkkko:,:lxkkkkkkkkkkkkko,.       .:dkkkkkkkkkkkkdol:,....cxkkkkkx:.                        //
//                .:xkkkkkkkkkkkkkkkd:..'okkkkkkx;              'okkkkkkkxxxkkkkkkkkkkkkkkdc'         .;dkkkkkkkkxdl;'..     .cxkkkkkkc.                        //
//                .;dkkkkkkxodkkkkkkkxc''lkkkkkkd;             .:dkkkkkkkkkkkkkkkkkkkkkkkx:.           .;dkkkkkkxl,.         .;xkkkkkkl.                        //
//                 ,dkkkkkko;;okkkkkkkxl:oxkkkkkx:.           .:dkkkkkkkkkkkkkkxxxkkkkkkkxl.            .ckkkkkkxl'           ,dkkkkkkl.                        //
//                 ,dkkkkkko'.'lxkkkkkkxddxkkkkkxc.          'lxkkkkkkkkkkkxdl:;,;lxkkkkkkd:.           .cxkkkkkkl'           'okkkkkkl.                        //
//                .;dkkkkkxl.  .cxkkkkkkkkkkkkkkkl'          ,okkkkkkkkkdoc;..   .,oxkkkkkxl,.          .:xkkkkkkl'           'okOkkkkd;.                       //
//                .lxkkkkkxc.   .:dkkkkkkkkkkkkkko,          'lxkkkkkkd:'.        .;dkkkkkkxl'          .:dkkkkkkl'           .lxkkkkkxl.                       //
//                'okkkkkkd:.    .,oxkkkkkkkkkkkkd;.         .lxkkkkkkl.           .lxkkkkkkx:.         .;dkkkkkxc.           .:xkkkkkkd,                       //
//                'lkkkkkkd:.      'lxkkkkkkkkkkkxc.         ,okkkkkkx:.           .,okkkkkkkd;.         'lxkkkko,             'lxkkkkko,                       //
//                'okkkkkkd;.       .cxkkkkkkkkkkko,        .;dkkkkkko,.            .:dkkkkkkko,          .:lol:'.              'lxkkkxl.                       //
//                'okkkkkkd;.        .:dkkkkkkkkkkx:.       'lxkkkkkxc.              'cxkkkkkkxl.           ...                  .:oxdl'.                       //
//                ,okkkkkko,.         .,okkkkkkkkkx:.      .;okkkkkxo'                'lxkkkkkkd,                                  ....                         //
//               .;dkkkkkko'            .cxkkkkkkkx:.       .cdxxxdl'                  .;oxkkkxl.                                                               //
//               .:dkkkkkxc.             .;okkkkkxo;.        .';:;,.                     .,clc:.                                                                //
//                .:odddo:.                ':lddo:'.                                        .                                                                   //
//                 ..''...                   ....                                                                                                               //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WITIK is ERC721Creator {
    constructor() ERC721Creator("What I Thought I Knew", "WITIK") {}
}