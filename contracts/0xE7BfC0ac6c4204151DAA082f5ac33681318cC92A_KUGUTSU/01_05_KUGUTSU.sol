// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ZOMB BURGER
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                               //
//                                                                                               //
//     _   ___   _ _____ _   _ _____ _____ _   _                                                 //
//    | | / / | | |  __ \ | | |_   _/  ___| | | |                                                //
//    | |/ /| | | | |  \/ | | | | | \ `--.| | | |                                                //
//    |    \| | | | | __| | | | | |  `--. \ | | |                                                //
//    | |\  \ |_| | |_\ \ |_| | | | /\__/ / |_| |                                                //
//    \_| \_/\___/ \____/\___/  \_/ \____/ \___/                                                 //
//                                                                                               //
//                                                                                               //
//                                                                                               //
//    Absurd...                                                                                  //
//    Hideously beautiful and beautifully hideous...                                             //
//    Meat-tacular...                                                                            //
//    Nauseating...                                                                              //
//    Hilariously disgusting...                                                                  //
//    Captivating and repulsive...                                                               //
//    Meatalicius...NFT                                                                          //
//                                                                                               //
//    Decaying physical sculpture made with carefully selected materials (dead animal parts).    //
//    The original artwork will be dismembered and disposed of the remains.                      //
//                                                                                               //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////


contract KUGUTSU is ERC1155Creator {
    constructor() ERC1155Creator("ZOMB BURGER", "KUGUTSU") {}
}