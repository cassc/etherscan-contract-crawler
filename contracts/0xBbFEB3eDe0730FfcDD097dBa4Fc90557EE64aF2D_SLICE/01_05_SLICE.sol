// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SLICES
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                       .;ll:.                                                                 //
//                                                                                   .;::oXMMNx;.                                                               //
//                                                                                 .,xWMMMMMMMMWo                                                               //
//                                                                                .OWWMMMMMMMMMMx....                                                           //
//                                                                                .dKNMMMMMMMMMMNKKKk'                                                          //
//                                                                                 .'kMMMMMMMMMMMMMMK;                                                          //
//                                                                                .dOXMMMMMMMMMMMMMMW0xxx:                                                      //
//                                                                             'odONMMMMMMMMMMMMMMMMMMMMMKdc.                                                   //
//                                                                           ,lkWMMMMMMMMMMMMMMMMMMMMMMMMMMNx:.                                                 //
//                                                                         ,c0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx;.                                               //
//                                                                      .'cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO;.                                             //
//                                                                     .lXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNO,.                                           //
//                                                                   .lKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXO,                                          //
//                                                                 .l0XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKk:                                        //
//                                                               .oOXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkc.                                     //
//                                                             'oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKd:.                                   //
//                                                           ,ckWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl'.                                 //
//                                                         'c0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXo,.                               //
//                                                      .'cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWk;.                             //
//                                                    ..lXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNO'                            //
//                                                   .oXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,                            //
//                                                 .o0XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWW0'                            //
//                                               .oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk;,,,,,,,,,'                             //
//                                             'oOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx:.                                        //
//                                           ,ckWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkllllldXN:                                          //
//                                        .'c0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKxxxo.     .ld'                                          //
//                                      ..cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOOOOOOO0XMMMMMWXO:           ..                                           //
//                                     .lXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKKXNMNKKKKk,       .oXNMMMNc            .ok,                                          //
//                                   .oKNMMMMMMMMMMMMMMMMMMMMWNNNWMMWNNNx....xMx.....         ..lNMMN:             ..                                           //
//                                 .o0XMMMMMMMMMMMMMMMMMMMMMXl'''cKXl'''.    dMd                :NMMN:                                                          //
//                                 .OMMMMMMMMMMMMMMXo;;;dNKl,.   .,,.        .:.                .,lKX:                                                          //
//                               .:xXMMMMMMMMMMOcxN0'   :NO'                 ,o,                  .OX;                                                          //
//                               ,KMMMMMMMXkdol' .lc.   :NO.                 ;d,                  .OX;                                                          //
//                               .oxddxkKWk.            :NO'                                      .ld'                                                          //
//                                      ;Oo.            ,kd.                                       ..                                                           //
//                                       ..              ..                                       .k0;                                                          //
//                                      ;Oo.            ,kd.                                      .OX;                                                          //
//                                      .'.             .'.                                        .'.                                                          //
//                                                                                                                                                              //
//                                                      .c:.                                                                                                    //
//                                                      .oc.                                                                                                    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SLICE is ERC1155Creator {
    constructor() ERC1155Creator("SLICES", "SLICE") {}
}