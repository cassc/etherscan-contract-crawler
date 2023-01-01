// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Alchemy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                          //
//    TTTTTTTTTTTTTTTTTTTTTTTHHHHHHHHH     HHHHHHHHHEEEEEEEEEEEEEEEEEEEEEE               AAA               LLLLLLLLLLL                    CCCCCCCCCCCCCHHHHHHHHH     HHHHHHHHHEEEEEEEEEEEEEEEEEEEEEEMMMMMMMM               MMMMMMMMYYYYYYY       YYYYYYY    //
//    T:::::::::::::::::::::TH:::::::H     H:::::::HE::::::::::::::::::::E              A:::A              L:::::::::L                 CCC::::::::::::CH:::::::H     H:::::::HE::::::::::::::::::::EM:::::::M             M:::::::MY:::::Y       Y:::::Y    //
//    T:::::::::::::::::::::TH:::::::H     H:::::::HE::::::::::::::::::::E             A:::::A             L:::::::::L               CC:::::::::::::::CH:::::::H     H:::::::HE::::::::::::::::::::EM::::::::M           M::::::::MY:::::Y       Y:::::Y    //
//    T:::::TT:::::::TT:::::THH::::::H     H::::::HHEE::::::EEEEEEEEE::::E            A:::::::A            LL:::::::LL              C:::::CCCCCCCC::::CHH::::::H     H::::::HHEE::::::EEEEEEEEE::::EM:::::::::M         M:::::::::MY::::::Y     Y::::::Y    //
//    TTTTTT  T:::::T  TTTTTT  H:::::H     H:::::H    E:::::E       EEEEEE           A:::::::::A             L:::::L               C:::::C       CCCCCC  H:::::H     H:::::H    E:::::E       EEEEEEM::::::::::M       M::::::::::MYYY:::::Y   Y:::::YYY    //
//            T:::::T          H:::::H     H:::::H    E:::::E                       A:::::A:::::A            L:::::L              C:::::C                H:::::H     H:::::H    E:::::E             M:::::::::::M     M:::::::::::M   Y:::::Y Y:::::Y       //
//            T:::::T          H::::::HHHHH::::::H    E::::::EEEEEEEEEE            A:::::A A:::::A           L:::::L              C:::::C                H::::::HHHHH::::::H    E::::::EEEEEEEEEE   M:::::::M::::M   M::::M:::::::M    Y:::::Y:::::Y        //
//            T:::::T          H:::::::::::::::::H    E:::::::::::::::E           A:::::A   A:::::A          L:::::L              C:::::C                H:::::::::::::::::H    E:::::::::::::::E   M::::::M M::::M M::::M M::::::M     Y:::::::::Y         //
//            T:::::T          H:::::::::::::::::H    E:::::::::::::::E          A:::::A     A:::::A         L:::::L              C:::::C                H:::::::::::::::::H    E:::::::::::::::E   M::::::M  M::::M::::M  M::::::M      Y:::::::Y          //
//            T:::::T          H::::::HHHHH::::::H    E::::::EEEEEEEEEE         A:::::AAAAAAAAA:::::A        L:::::L              C:::::C                H::::::HHHHH::::::H    E::::::EEEEEEEEEE   M::::::M   M:::::::M   M::::::M       Y:::::Y           //
//            T:::::T          H:::::H     H:::::H    E:::::E                  A:::::::::::::::::::::A       L:::::L              C:::::C                H:::::H     H:::::H    E:::::E             M::::::M    M:::::M    M::::::M       Y:::::Y           //
//            T:::::T          H:::::H     H:::::H    E:::::E       EEEEEE    A:::::AAAAAAAAAAAAA:::::A      L:::::L         LLLLLLC:::::C       CCCCCC  H:::::H     H:::::H    E:::::E       EEEEEEM::::::M     MMMMM     M::::::M       Y:::::Y           //
//          TT:::::::TT      HH::::::H     H::::::HHEE::::::EEEEEEEE:::::E   A:::::A             A:::::A   LL:::::::LLLLLLLLL:::::L C:::::CCCCCCCC::::CHH::::::H     H::::::HHEE::::::EEEEEEEE:::::EM::::::M               M::::::M       Y:::::Y           //
//          T:::::::::T      H:::::::H     H:::::::HE::::::::::::::::::::E  A:::::A               A:::::A  L::::::::::::::::::::::L  CC:::::::::::::::CH:::::::H     H:::::::HE::::::::::::::::::::EM::::::M               M::::::M    YYYY:::::YYYY        //
//          T:::::::::T      H:::::::H     H:::::::HE::::::::::::::::::::E A:::::A                 A:::::A L::::::::::::::::::::::L    CCC::::::::::::CH:::::::H     H:::::::HE::::::::::::::::::::EM::::::M               M::::::M    Y:::::::::::Y        //
//          TTTTTTTTTTT      HHHHHHHHH     HHHHHHHHHEEEEEEEEEEEEEEEEEEEEEEAAAAAAA                   AAAAAAALLLLLLLLLLLLLLLLLLLLLLLL       CCCCCCCCCCCCCHHHHHHHHH     HHHHHHHHHEEEEEEEEEEEEEEEEEEEEEEMMMMMMMM               MMMMMMMM    YYYYYYYYYYYYY        //
//                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ALCMY is ERC721Creator {
    constructor() ERC721Creator("The Alchemy", "ALCMY") {}
}