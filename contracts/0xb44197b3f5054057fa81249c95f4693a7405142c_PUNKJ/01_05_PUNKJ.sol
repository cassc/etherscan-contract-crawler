// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Journey by PabloPunkasso
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll:,,,,:llllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllc'    'clllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllccccclllllllllllcccccllllllllllllllllcccc.    'cllllcclclllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllc,....,clllllllc,....,clllllllllllllc,.....,,,,:lllc,....,clllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllc.    .clllllllc.    .clllllllllllllc.    .clllllllc.    .clllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllll:,,,,......,,,,:lllc.    .,,,,:lllc:;,,,,.    .,,,,,,,,,.    .clllllllc:,,,,:lllllllllllllllllll    //
//    lllllllllllllllllllllllc'    .cclc.    'cllc.         'cllc'                         .clllllllc'    'cllllllllllllllllll    //
//    lllllllllllllllccccllllc.    .clcc.    .cccc.         .cccc.                         .cllllcccc.    'cllllllllllllllllll    //
//    lllllllllllllc,....,cllc.     ....      ....           ....                          .cllc,.....,,,,:cllllllllllllllllll    //
//    lllllllllllllc.    .cllc.                                                            .cllc.    .clllllllllllllllllllllll    //
//    lllllllllllllc,.....,,,,.                                                            .,,,,.    .clllllllllllllllllllllll    //
//    llllllllllllllccccc.                                                                           .clllllllllllllllllllllll    //
//    lllllllllllllllcccc.                                                                           .ccccllllllllllllllllllll    //
//    lllllllllllllc,....                                                                             ....,cllllllllllllllllll    //
//    lllllllllllllc.                                                                                     .cllllllllllllllllll    //
//    lllllllllllllc,....                                                                             ....,cllllllllllllllllll    //
//    llllllllllllllccccc.                                                                           .ccccllllllllllllllllllll    //
//    lllllllllllllllcclc.                                                                           'clllllllllllllllllllllll    //
//    lllllllllllllc,....                                        'lodddddddo'                   .,,,,:llllllllllllllllllllllll    //
//    lllllllllllllc.                                            c0KXXXXXXXKc                   'cllllllllllllllllllllllllllll    //
//    lllllllll:,,,,.                             .'''''''''.    'lodddOXXXKd,'''.              .,,,,:clllllllllllllllllllllll    //
//    llllllllc'                                  :0XKXKKKXK:          cKXXXXKKX0:                   'clllllllllllllllllllllll    //
//    llllllllc'                                  :KXKKXKKXK:          :KXKXKKKXK:                   .ccccllllllllllllllllllll    //
//    lllllllll:,,,,,,,,,.                        .''''''','.          .'''''''''.                    ....,cllllllllllllllllll    //
//    llllllllllllllllllc.                                                                                .cllllllllllllllllll    //
//    llllllllllllll:,,,,.                    .............................................           ....,cllllllllllllllllll    //
//    lllllllllllllc'                        'looodkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkdoool'         .ccccllllllllllllllllllll    //
//    lllllllllllllc.                        'ooooxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdooo'         .clllllllllllllllllllllll    //
//    lllllllllllllc.    .,,,,.         .;;;;lxxkxc'.................................'cxxkx,         'clllllllllllllllllllllll    //
//    lllllllllllllc.    .cllc.         'ooooxkOOk;                                   ;kOOk;         .clllllllllllllllllllllll    //
//    lllllllllllllc,.....,,,,.         'ooooxkOOk;                                   ;kOOk;         .,,,,:lllllllllllllllllll    //
//    lllllllllllllllcccc.              'ooooxkOkk;                                   ;kOOk;              'cllllllllllllllllll    //
//    llllllllllllllllllc.              'loooxkkkk;                                   ;kkOk;              'cllllllllllllllllll    //
//    llllllllllllllllllc.    .,,,,.     ....:ddddolccccccccccccccccccccccccccccccccccodddd,    .,,,,,,,,,:lllllllllllllllllll    //
//    llllllllllllllllllc.    .cllc.         'ooooxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxoooo'    .cllllllllllllllllllllllllllll    //
//    llllllllllllllllllc,....,cllc.         .;;;;:ccccccccccccccccccccccccccccccccccc:;;;;.    .cllllllllllllllllllllllllllll    //
//    llllllllllllllllllllccccllllc.                                                            .cllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllcclc.                                                            .cllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllc,.....,,,,.    'oddddddddddddddddddddddddddddddddddddddo'         .cllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllc.    .cllc.    cKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKc         .cllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllc,....,cllc.    cKXXXXXXXXXXXXX0kkkkkkkkkkkkkkk0XXXXXXXXKc     .....,,,,:llllllllllllllllllllllll    //
//    lllllllllllllllllllllllllcclcllllc.    cKXXXXXXXXXXXXKd;,,,,,,,,,,,,,;dKXXXXXXXKc    .cccc.    'clllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllc'    cKXKKXXXXXXXXXKd;,,,,,,,,,,,,,;dKXXXXKKXKc    'cllc'    'clllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll:,,,,,''',dKXXXXXXXX0kkkkkkkkkkkkkkk0XXXKd,''',,,,,:llll:,,,,:llllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllc.    cKXXXXXXXXXXXXXXXXXXXXXXXXXXXXKc    .cllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllc.    cKXXXOddddOXXXXXXXXXXXXXXXOdddo;....,cllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllc.    cKXXKc    cKXXXXXXXXXXXXXKc    .clccllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllc.    cKXXKc    c0XXKKXXKKKKKKXKc    'clllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllc.    cKXXXOdddoc,'''',''''''''',,,,,:llllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllc.    cKXXXXXXXKc               .cllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllc.    cKXXXXXXXKd,'''.      ....,cllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllc.    cKXXXXXXXXXKKX0:     .clccllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllc.    cKXXXXXXXXXXXXKc     .clllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllc.    cKXXXXXXXXXXXXKc     .clllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllc.    cKXXXXXXXXXXXXKc     .clllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllc.    cKXXXXXXXXXXXXKc     .clllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PUNKJ is ERC721Creator {
    constructor() ERC721Creator("The Journey by PabloPunkasso", "PUNKJ") {}
}