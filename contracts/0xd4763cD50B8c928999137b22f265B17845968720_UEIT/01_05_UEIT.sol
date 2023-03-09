// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Un' estate Italiana
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                   AAA               NNNNNNNN        NNNNNNNN                                                                                                       //
//                  A:::A              N:::::::N       N::::::N                                                                                                       //
//                 A:::::A             N::::::::N      N::::::N                                                                                                       //
//                A:::::::A            N:::::::::N     N::::::N                                                                                                       //
//               A:::::::::A           N::::::::::N    N::::::N                                                                                                       //
//              A:::::A:::::A          N:::::::::::N   N::::::N                                                                                                       //
//             A:::::A A:::::A         N:::::::N::::N  N::::::N                                                                                                       //
//            A:::::A   A:::::A        N::::::N N::::N N::::::N                                                                                                       //
//           A:::::A     A:::::A       N::::::N  N::::N:::::::N                                                                                                       //
//          A:::::AAAAAAAAA:::::A      N::::::N   N:::::::::::N                                                                                                       //
//         A:::::::::::::::::::::A     N::::::N    N::::::::::N                                                                                                       //
//        A:::::AAAAAAAAAAAAA:::::A    N::::::N     N:::::::::N                                                                                                       //
//       A:::::A             A:::::A   N::::::N      N::::::::N                                                                                                       //
//      A:::::A               A:::::A  N::::::N       N:::::::N                                                                                                       //
//     A:::::A                 A:::::A N::::::N        N::::::N                                                                                                       //
//    AAAAAAA                   AAAAAAANNNNNNNN         NNNNNNN                                                                                                       //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//    IIIIIIIIIITTTTTTTTTTTTTTTTTTTTTTT         AAA               LLLLLLLLLLL             IIIIIIIIII               AAA               NNNNNNNN        NNNNNNNN         //
//    I::::::::IT:::::::::::::::::::::T        A:::A              L:::::::::L             I::::::::I              A:::A              N:::::::N       N::::::N         //
//    I::::::::IT:::::::::::::::::::::T       A:::::A             L:::::::::L             I::::::::I             A:::::A             N::::::::N      N::::::N         //
//    II::::::IIT:::::TT:::::::TT:::::T      A:::::::A            LL:::::::LL             II::::::II            A:::::::A            N:::::::::N     N::::::N         //
//      I::::I  TTTTTT  T:::::T  TTTTTT     A:::::::::A             L:::::L                 I::::I             A:::::::::A           N::::::::::N    N::::::N         //
//      I::::I          T:::::T            A:::::A:::::A            L:::::L                 I::::I            A:::::A:::::A          N:::::::::::N   N::::::N         //
//      I::::I          T:::::T           A:::::A A:::::A           L:::::L                 I::::I           A:::::A A:::::A         N:::::::N::::N  N::::::N         //
//      I::::I          T:::::T          A:::::A   A:::::A          L:::::L                 I::::I          A:::::A   A:::::A        N::::::N N::::N N::::::N         //
//      I::::I          T:::::T         A:::::A     A:::::A         L:::::L                 I::::I         A:::::A     A:::::A       N::::::N  N::::N:::::::N         //
//      I::::I          T:::::T        A:::::AAAAAAAAA:::::A        L:::::L                 I::::I        A:::::AAAAAAAAA:::::A      N::::::N   N:::::::::::N         //
//      I::::I          T:::::T       A:::::::::::::::::::::A       L:::::L                 I::::I       A:::::::::::::::::::::A     N::::::N    N::::::::::N         //
//      I::::I          T:::::T      A:::::AAAAAAAAAAAAA:::::A      L:::::L         LLLLLL  I::::I      A:::::AAAAAAAAAAAAA:::::A    N::::::N     N:::::::::N         //
//    II::::::II      TT:::::::TT   A:::::A             A:::::A   LL:::::::LLLLLLLLL:::::LII::::::II   A:::::A             A:::::A   N::::::N      N::::::::N         //
//    I::::::::I      T:::::::::T  A:::::A               A:::::A  L::::::::::::::::::::::LI::::::::I  A:::::A               A:::::A  N::::::N       N:::::::N         //
//    I::::::::I      T:::::::::T A:::::A                 A:::::A L::::::::::::::::::::::LI::::::::I A:::::A                 A:::::A N::::::N        N::::::N         //
//    IIIIIIIIII      TTTTTTTTTTTAAAAAAA                   AAAAAAALLLLLLLLLLLLLLLLLLLLLLLLIIIIIIIIIIAAAAAAA                   AAAAAAANNNNNNNN         NNNNNNN         //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//       SSSSSSSSSSSSSSS UUUUUUUU     UUUUUUUUMMMMMMMM               MMMMMMMMMMMMMMMM               MMMMMMMMEEEEEEEEEEEEEEEEEEEEEERRRRRRRRRRRRRRRRR                   //
//     SS:::::::::::::::SU::::::U     U::::::UM:::::::M             M:::::::MM:::::::M             M:::::::ME::::::::::::::::::::ER::::::::::::::::R                  //
//    S:::::SSSSSS::::::SU::::::U     U::::::UM::::::::M           M::::::::MM::::::::M           M::::::::ME::::::::::::::::::::ER::::::RRRRRR:::::R                 //
//    S:::::S     SSSSSSSUU:::::U     U:::::UUM:::::::::M         M:::::::::MM:::::::::M         M:::::::::MEE::::::EEEEEEEEE::::ERR:::::R     R:::::R                //
//    S:::::S             U:::::U     U:::::U M::::::::::M       M::::::::::MM::::::::::M       M::::::::::M  E:::::E       EEEEEE  R::::R     R:::::R                //
//    S:::::S             U:::::D     D:::::U M:::::::::::M     M:::::::::::MM:::::::::::M     M:::::::::::M  E:::::E               R::::R     R:::::R                //
//     S::::SSSS          U:::::D     D:::::U M:::::::M::::M   M::::M:::::::MM:::::::M::::M   M::::M:::::::M  E::::::EEEEEEEEEE     R::::RRRRRR:::::R                 //
//      SS::::::SSSSS     U:::::D     D:::::U M::::::M M::::M M::::M M::::::MM::::::M M::::M M::::M M::::::M  E:::::::::::::::E     R:::::::::::::RR                  //
//        SSS::::::::SS   U:::::D     D:::::U M::::::M  M::::M::::M  M::::::MM::::::M  M::::M::::M  M::::::M  E:::::::::::::::E     R::::RRRRRR:::::R                 //
//           SSSSSS::::S  U:::::D     D:::::U M::::::M   M:::::::M   M::::::MM::::::M   M:::::::M   M::::::M  E::::::EEEEEEEEEE     R::::R     R:::::R                //
//                S:::::S U:::::D     D:::::U M::::::M    M:::::M    M::::::MM::::::M    M:::::M    M::::::M  E:::::E               R::::R     R:::::R                //
//                S:::::S U::::::U   U::::::U M::::::M     MMMMM     M::::::MM::::::M     MMMMM     M::::::M  E:::::E       EEEEEE  R::::R     R:::::R                //
//    SSSSSSS     S:::::S U:::::::UUU:::::::U M::::::M               M::::::MM::::::M               M::::::MEE::::::EEEEEEEE:::::ERR:::::R     R:::::R                //
//    S::::::SSSSSS:::::S  UU:::::::::::::UU  M::::::M               M::::::MM::::::M               M::::::ME::::::::::::::::::::ER::::::R     R:::::R                //
//    S:::::::::::::::SS     UU:::::::::UU    M::::::M               M::::::MM::::::M               M::::::ME::::::::::::::::::::ER::::::R     R:::::R                //
//     SSSSSSSSSSSSSSS         UUUUUUUUU      MMMMMMMM               MMMMMMMMMMMMMMMM               MMMMMMMMEEEEEEEEEEEEEEEEEEEEEERRRRRRRR     RRRRRRR                //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
//                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract UEIT is ERC721Creator {
    constructor() ERC721Creator("Un' estate Italiana", "UEIT") {}
}