// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MARTINSLIDE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                   //
//    MMMMMMMM               MMMMMMMM               AAA               RRRRRRRRRRRRRRRRR   TTTTTTTTTTTTTTTTTTTTTTTIIIIIIIIIINNNNNNNN        NNNNNNNN   SSSSSSSSSSSSSSS LLLLLLLLLLL             IIIIIIIIIIDDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEE    //
//    M:::::::M             M:::::::M              A:::A              R::::::::::::::::R  T:::::::::::::::::::::TI::::::::IN:::::::N       N::::::N SS:::::::::::::::SL:::::::::L             I::::::::ID::::::::::::DDD   E::::::::::::::::::::E    //
//    M::::::::M           M::::::::M             A:::::A             R::::::RRRRRR:::::R T:::::::::::::::::::::TI::::::::IN::::::::N      N::::::NS:::::SSSSSS::::::SL:::::::::L             I::::::::ID:::::::::::::::DD E::::::::::::::::::::E    //
//    M:::::::::M         M:::::::::M            A:::::::A            RR:::::R     R:::::RT:::::TT:::::::TT:::::TII::::::IIN:::::::::N     N::::::NS:::::S     SSSSSSSLL:::::::LL             II::::::IIDDD:::::DDDDD:::::DEE::::::EEEEEEEEE::::E    //
//    M::::::::::M       M::::::::::M           A:::::::::A             R::::R     R:::::RTTTTTT  T:::::T  TTTTTT  I::::I  N::::::::::N    N::::::NS:::::S              L:::::L                 I::::I    D:::::D    D:::::D E:::::E       EEEEEE    //
//    M:::::::::::M     M:::::::::::M          A:::::A:::::A            R::::R     R:::::R        T:::::T          I::::I  N:::::::::::N   N::::::NS:::::S              L:::::L                 I::::I    D:::::D     D:::::DE:::::E                 //
//    M:::::::M::::M   M::::M:::::::M         A:::::A A:::::A           R::::RRRRRR:::::R         T:::::T          I::::I  N:::::::N::::N  N::::::N S::::SSSS           L:::::L                 I::::I    D:::::D     D:::::DE::::::EEEEEEEEEE       //
//    M::::::M M::::M M::::M M::::::M        A:::::A   A:::::A          R:::::::::::::RR          T:::::T          I::::I  N::::::N N::::N N::::::N  SS::::::SSSSS      L:::::L                 I::::I    D:::::D     D:::::DE:::::::::::::::E       //
//    M::::::M  M::::M::::M  M::::::M       A:::::A     A:::::A         R::::RRRRRR:::::R         T:::::T          I::::I  N::::::N  N::::N:::::::N    SSS::::::::SS    L:::::L                 I::::I    D:::::D     D:::::DE:::::::::::::::E       //
//    M::::::M   M:::::::M   M::::::M      A:::::AAAAAAAAA:::::A        R::::R     R:::::R        T:::::T          I::::I  N::::::N   N:::::::::::N       SSSSSS::::S   L:::::L                 I::::I    D:::::D     D:::::DE::::::EEEEEEEEEE       //
//    M::::::M    M:::::M    M::::::M     A:::::::::::::::::::::A       R::::R     R:::::R        T:::::T          I::::I  N::::::N    N::::::::::N            S:::::S  L:::::L                 I::::I    D:::::D     D:::::DE:::::E                 //
//    M::::::M     MMMMM     M::::::M    A:::::AAAAAAAAAAAAA:::::A      R::::R     R:::::R        T:::::T          I::::I  N::::::N     N:::::::::N            S:::::S  L:::::L         LLLLLL  I::::I    D:::::D    D:::::D E:::::E       EEEEEE    //
//    M::::::M               M::::::M   A:::::A             A:::::A   RR:::::R     R:::::R      TT:::::::TT      II::::::IIN::::::N      N::::::::NSSSSSSS     S:::::SLL:::::::LLLLLLLLL:::::LII::::::IIDDD:::::DDDDD:::::DEE::::::EEEEEEEE:::::E    //
//    M::::::M               M::::::M  A:::::A               A:::::A  R::::::R     R:::::R      T:::::::::T      I::::::::IN::::::N       N:::::::NS::::::SSSSSS:::::SL::::::::::::::::::::::LI::::::::ID:::::::::::::::DD E::::::::::::::::::::E    //
//    M::::::M               M::::::M A:::::A                 A:::::A R::::::R     R:::::R      T:::::::::T      I::::::::IN::::::N        N::::::NS:::::::::::::::SS L::::::::::::::::::::::LI::::::::ID::::::::::::DDD   E::::::::::::::::::::E    //
//    MMMMMMMM               MMMMMMMMAAAAAAA                   AAAAAAARRRRRRRR     RRRRRRR      TTTTTTTTTTT      IIIIIIIIIINNNNNNNN         NNNNNNN SSSSSSSSSSSSSSS   LLLLLLLLLLLLLLLLLLLLLLLLIIIIIIIIIIDDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEE    //
//                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AMMS is ERC721Creator {
    constructor() ERC721Creator("MARTINSLIDE", "AMMS") {}
}