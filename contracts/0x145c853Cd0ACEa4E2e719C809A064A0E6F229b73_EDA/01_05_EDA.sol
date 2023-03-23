// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: El_deAlex
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                   //
//                                                                                                                                                                                   //
//                                                                                                                                                                                   //
//                                                                      dddddddd                                                                                                     //
//    EEEEEEEEEEEEEEEEEEEEEElllllll                                     d::::::d                                 AAA               lllllll                                           //
//    E::::::::::::::::::::El:::::l                                     d::::::d                                A:::A              l:::::l                                           //
//    E::::::::::::::::::::El:::::l                                     d::::::d                               A:::::A             l:::::l                                           //
//    EE::::::EEEEEEEEE::::El:::::l                                     d:::::d                               A:::::::A            l:::::l                                           //
//      E:::::E       EEEEEE l::::l                             ddddddddd:::::d     eeeeeeeeeeee             A:::::::::A            l::::l     eeeeeeeeeeee  xxxxxxx      xxxxxxx    //
//      E:::::E              l::::l                           dd::::::::::::::d   ee::::::::::::ee          A:::::A:::::A           l::::l   ee::::::::::::ee x:::::x    x:::::x     //
//      E::::::EEEEEEEEEE    l::::l                          d::::::::::::::::d  e::::::eeeee:::::ee       A:::::A A:::::A          l::::l  e::::::eeeee:::::eex:::::x  x:::::x      //
//      E:::::::::::::::E    l::::l                         d:::::::ddddd:::::d e::::::e     e:::::e      A:::::A   A:::::A         l::::l e::::::e     e:::::e x:::::xx:::::x       //
//      E:::::::::::::::E    l::::l                         d::::::d    d:::::d e:::::::eeeee::::::e     A:::::A     A:::::A        l::::l e:::::::eeeee::::::e  x::::::::::x        //
//      E::::::EEEEEEEEEE    l::::l                         d:::::d     d:::::d e:::::::::::::::::e     A:::::AAAAAAAAA:::::A       l::::l e:::::::::::::::::e    x::::::::x         //
//      E:::::E              l::::l                         d:::::d     d:::::d e::::::eeeeeeeeeee     A:::::::::::::::::::::A      l::::l e::::::eeeeeeeeeee     x::::::::x         //
//      E:::::E       EEEEEE l::::l                         d:::::d     d:::::d e:::::::e             A:::::AAAAAAAAAAAAA:::::A     l::::l e:::::::e             x::::::::::x        //
//    EE::::::EEEEEEEE:::::El::::::l                        d::::::ddddd::::::dde::::::::e           A:::::A             A:::::A   l::::::le::::::::e           x:::::xx:::::x       //
//    E::::::::::::::::::::El::::::l                         d:::::::::::::::::d e::::::::eeeeeeee  A:::::A               A:::::A  l::::::l e::::::::eeeeeeee  x:::::x  x:::::x      //
//    E::::::::::::::::::::El::::::l                          d:::::::::ddd::::d  ee:::::::::::::e A:::::A                 A:::::A l::::::l  ee:::::::::::::e x:::::x    x:::::x     //
//    EEEEEEEEEEEEEEEEEEEEEEllllllll                           ddddddddd   ddddd    eeeeeeeeeeeeeeAAAAAAA                   AAAAAAAllllllll    eeeeeeeeeeeeeexxxxxxx      xxxxxxx    //
//                                  ________________________                                                                                                                         //
//                                  _::::::::::::::::::::::_                                                                                                                         //
//                                  ________________________                                                                                                                         //
//                                                                                                                                                                                   //
//                                                                                                                                                                                   //
//                                                                                                                                                                                   //
//                                                                                                                                                                                   //
//                                                                                                                                                                                   //
//                                                                                                                                                                                   //
//                                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EDA is ERC721Creator {
    constructor() ERC721Creator("El_deAlex", "EDA") {}
}