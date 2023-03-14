// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PERALTINHA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                          //
//    PPPPPPPPPPPPPPPPP   EEEEEEEEEEEEEEEEEEEEEERRRRRRRRRRRRRRRRR                  AAA               LLLLLLLLLLL       TTTTTTTTTTTTTTTTTTTTTTTIIIIIIIIIINNNNNNNN        NNNNNNNNHHHHHHHHH     HHHHHHHHH               AAA                   //
//    P::::::::::::::::P  E::::::::::::::::::::ER::::::::::::::::R                A:::A              L:::::::::L       T:::::::::::::::::::::TI::::::::IN:::::::N       N::::::NH:::::::H     H:::::::H              A:::A                  //
//    P::::::PPPPPP:::::P E::::::::::::::::::::ER::::::RRRRRR:::::R              A:::::A             L:::::::::L       T:::::::::::::::::::::TI::::::::IN::::::::N      N::::::NH:::::::H     H:::::::H             A:::::A                 //
//    PP:::::P     P:::::PEE::::::EEEEEEEEE::::ERR:::::R     R:::::R            A:::::::A            LL:::::::LL       T:::::TT:::::::TT:::::TII::::::IIN:::::::::N     N::::::NHH::::::H     H::::::HH            A:::::::A                //
//      P::::P     P:::::P  E:::::E       EEEEEE  R::::R     R:::::R           A:::::::::A             L:::::L         TTTTTT  T:::::T  TTTTTT  I::::I  N::::::::::N    N::::::N  H:::::H     H:::::H             A:::::::::A               //
//      P::::P     P:::::P  E:::::E               R::::R     R:::::R          A:::::A:::::A            L:::::L                 T:::::T          I::::I  N:::::::::::N   N::::::N  H:::::H     H:::::H            A:::::A:::::A              //
//      P::::PPPPPP:::::P   E::::::EEEEEEEEEE     R::::RRRRRR:::::R          A:::::A A:::::A           L:::::L                 T:::::T          I::::I  N:::::::N::::N  N::::::N  H::::::HHHHH::::::H           A:::::A A:::::A             //
//      P:::::::::::::PP    E:::::::::::::::E     R:::::::::::::RR          A:::::A   A:::::A          L:::::L                 T:::::T          I::::I  N::::::N N::::N N::::::N  H:::::::::::::::::H          A:::::A   A:::::A            //
//      P::::PPPPPPPPP      E:::::::::::::::E     R::::RRRRRR:::::R        A:::::A     A:::::A         L:::::L                 T:::::T          I::::I  N::::::N  N::::N:::::::N  H:::::::::::::::::H         A:::::A     A:::::A           //
//      P::::P              E::::::EEEEEEEEEE     R::::R     R:::::R      A:::::AAAAAAAAA:::::A        L:::::L                 T:::::T          I::::I  N::::::N   N:::::::::::N  H::::::HHHHH::::::H        A:::::AAAAAAAAA:::::A          //
//      P::::P              E:::::E               R::::R     R:::::R     A:::::::::::::::::::::A       L:::::L                 T:::::T          I::::I  N::::::N    N::::::::::N  H:::::H     H:::::H       A:::::::::::::::::::::A         //
//      P::::P              E:::::E       EEEEEE  R::::R     R:::::R    A:::::AAAAAAAAAAAAA:::::A      L:::::L         LLLLLL  T:::::T          I::::I  N::::::N     N:::::::::N  H:::::H     H:::::H      A:::::AAAAAAAAAAAAA:::::A        //
//    PP::::::PP          EE::::::EEEEEEEE:::::ERR:::::R     R:::::R   A:::::A             A:::::A   LL:::::::LLLLLLLLL:::::LTT:::::::TT      II::::::IIN::::::N      N::::::::NHH::::::H     H::::::HH   A:::::A             A:::::A       //
//    P::::::::P          E::::::::::::::::::::ER::::::R     R:::::R  A:::::A               A:::::A  L::::::::::::::::::::::LT:::::::::T      I::::::::IN::::::N       N:::::::NH:::::::H     H:::::::H  A:::::A               A:::::A      //
//    P::::::::P          E::::::::::::::::::::ER::::::R     R:::::R A:::::A                 A:::::A L::::::::::::::::::::::LT:::::::::T      I::::::::IN::::::N        N::::::NH:::::::H     H:::::::H A:::::A                 A:::::A     //
//    PPPPPPPPPP          EEEEEEEEEEEEEEEEEEEEEERRRRRRRR     RRRRRRRAAAAAAA                   AAAAAAALLLLLLLLLLLLLLLLLLLLLLLLTTTTTTTTTTT      IIIIIIIIIINNNNNNNN         NNNNNNNHHHHHHHHH     HHHHHHHHHAAAAAAA                   AAAAAAA    //
//                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PLT is ERC721Creator {
    constructor() ERC721Creator("PERALTINHA", "PLT") {}
}