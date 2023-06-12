// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Love
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//               'odddddo'            .;ldkOOOkxoc,.     'odddddd,   'odddddd, .cdddddddddddddd;              //
//               cNMMMMMNc          .c0WMMMMMMMMMMNO:.   ;KMMMMMWo   lWMMMMMX: .kMMMMMMMMMMMMMMd              //
//               cNMMMMMNc         .dWMMMMMMMMMMMMMMNl.  .OMMMMMMx. .dMMMMMM0' .kMMMMMMMMMMMMMMd              //
//               cNMMMMMNc         cNMMMMMMKxkXMMMMMMK;  .dMMMMMMO. .kMMMMMMx. .kMMMMMMN0kkkkkk:              //
//               cNMMMMMNc         dMMMMMMX:  oWMMMMMWc   cNMMMMMK, '0MMMMMWl  .kMMMMMM0'                     //
//               cNMMMMMNc        .dMMMMMM0'  cNMMMMMWl   ,0MMMMMN: ;XMMMMMX;  .kMMMMMM0'                     //
//               cNMMMMMNc        .dMMMMMM0'  cNMMMMMWl   .kMMMMMWl cWMMMMMO.  .kMMMMMM0, .                   //
//               cNMMMMMNc        .dMMMMMM0'  cNMMMMMWl    oWMMMMMd.dMMMMMMd.  .kMMMMMMWKOOOOOk,              //
//               cNMMMMMNc        .dMMMMMM0'  cNMMMMMWl    :XMMMMMk,xMMMMMNc   .kMMMMMMMMMMMMMN:              //
//               cNMMMMMNc        .dMMMMMM0'  cNMMMMMWl    '0MMMMMOlOMMMMMK,   .kMMMMMMMMMMMMMN:              //
//               cNMMMMMNc        .dMMMMMM0'  cNMMMMMWl    .xMMMMMKkKMMMMMk.   .kMMMMMMXdcllllc.              //
//               cNMMMMMNc        .dMMMMMM0'  cNMMMMMWl     lWMMMMWNWMMMMWo    .kMMMMMM0'                     //
//               cNMMMMMNc        .dMMMMMM0'  cNMMMMMWl     ;KMMMMMMMMMMMN:    .kMMMMMM0'                     //
//               cNMMMMMNc         dMMMMMMK;  lWMMMMMNc     .OMMMMMMMMMMM0'    .kMMMMMM0'                     //
//               cNMMMMMWOooooool' cNMMMMMW0loKMMMMMMK;     .dMMMMMMMMMMMx.    .kMMMMMMNkooooooc.             //
//               cNMMMMMMMMMMMMMN: .xWMMMMMMMMMMMMMMNo.      cNMMMMMMMMMWl     .kMMMMMMMMMMMMMMK,             //
//               cNMMMMMMMMMMMMMN:  .oXMMMMMMMMMMMWKc.       ,KMMMMMMMMMX;     .kMMMMMMMMMMMMMMK,             //
//               ;kOOOOOOOOOOOOOk,    'cxO0KXXK0Od:.         .oOOOOOOOOOo.     .oOOOOOOOOOOOOOOd.             //
//                 .           .          ......               .  ...  .         .          ...               //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract love is ERC721Creator {
    constructor() ERC721Creator("Love", "love") {}
}