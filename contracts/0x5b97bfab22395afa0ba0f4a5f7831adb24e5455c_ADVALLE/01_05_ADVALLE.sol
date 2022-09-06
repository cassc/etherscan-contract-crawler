// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aimee Del Valle
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                   //
//                                                                                                                                   //
//                                                                                                                                   //
//                                                                                                                                   //
//                                                                                                                                   //
//                   AAA               IIIIIIIIIIMMMMMMMM               MMMMMMMMEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE         //
//                  A:::A              I::::::::IM:::::::M             M:::::::ME::::::::::::::::::::EE::::::::::::::::::::E         //
//                 A:::::A             I::::::::IM::::::::M           M::::::::ME::::::::::::::::::::EE::::::::::::::::::::E         //
//                A:::::::A            II::::::IIM:::::::::M         M:::::::::MEE::::::EEEEEEEEE::::EEE::::::EEEEEEEEE::::E         //
//               A:::::::::A             I::::I  M::::::::::M       M::::::::::M  E:::::E       EEEEEE  E:::::E       EEEEEE         //
//              A:::::A:::::A            I::::I  M:::::::::::M     M:::::::::::M  E:::::E               E:::::E                      //
//             A:::::A A:::::A           I::::I  M:::::::M::::M   M::::M:::::::M  E::::::EEEEEEEEEE     E::::::EEEEEEEEEE            //
//            A:::::A   A:::::A          I::::I  M::::::M M::::M M::::M M::::::M  E:::::::::::::::E     E:::::::::::::::E            //
//           A:::::A     A:::::A         I::::I  M::::::M  M::::M::::M  M::::::M  E:::::::::::::::E     E:::::::::::::::E            //
//          A:::::AAAAAAAAA:::::A        I::::I  M::::::M   M:::::::M   M::::::M  E::::::EEEEEEEEEE     E::::::EEEEEEEEEE            //
//         A:::::::::::::::::::::A       I::::I  M::::::M    M:::::M    M::::::M  E:::::E               E:::::E                      //
//        A:::::AAAAAAAAAAAAA:::::A      I::::I  M::::::M     MMMMM     M::::::M  E:::::E       EEEEEE  E:::::E       EEEEEE         //
//       A:::::A             A:::::A   II::::::IIM::::::M               M::::::MEE::::::EEEEEEEE:::::EEE::::::EEEEEEEE:::::E         //
//      A:::::A               A:::::A  I::::::::IM::::::M               M::::::ME::::::::::::::::::::EE::::::::::::::::::::E         //
//     A:::::A                 A:::::A I::::::::IM::::::M               M::::::ME::::::::::::::::::::EE::::::::::::::::::::E         //
//    AAAAAAA                   AAAAAAAIIIIIIIIIIMMMMMMMM               MMMMMMMMEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE         //
//                                  DDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEELLLLLLLLLLL                                             //
//                                  D::::::::::::DDD   E::::::::::::::::::::EL:::::::::L                                             //
//                                  D:::::::::::::::DD E::::::::::::::::::::EL:::::::::L                                             //
//                                  DDD:::::DDDDD:::::DEE::::::EEEEEEEEE::::ELL:::::::LL                                             //
//                                    D:::::D    D:::::D E:::::E       EEEEEE  L:::::L                                               //
//                                    D:::::D     D:::::DE:::::E               L:::::L                                               //
//                                    D:::::D     D:::::DE::::::EEEEEEEEEE     L:::::L                                               //
//                                    D:::::D     D:::::DE:::::::::::::::E     L:::::L                                               //
//                                    D:::::D     D:::::DE:::::::::::::::E     L:::::L                                               //
//                                    D:::::D     D:::::DE::::::EEEEEEEEEE     L:::::L                                               //
//                                    D:::::D     D:::::DE:::::E               L:::::L                                               //
//                                    D:::::D    D:::::D E:::::E       EEEEEE  L:::::L         LLLLLL                                //
//                                  DDD:::::DDDDD:::::DEE::::::EEEEEEEE:::::ELL:::::::LLLLLLLLL:::::L                                //
//                                  D:::::::::::::::DD E::::::::::::::::::::EL::::::::::::::::::::::L                                //
//                                  D::::::::::::DDD   E::::::::::::::::::::EL::::::::::::::::::::::L                                //
//                                  DDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEELLLLLLLLLLLLLLLLLLLLLLLL                                //
//    VVVVVVVV           VVVVVVVV   AAA               LLLLLLLLLLL             LLLLLLLLLLL             EEEEEEEEEEEEEEEEEEEEEE         //
//    V::::::V           V::::::V  A:::A              L:::::::::L             L:::::::::L             E::::::::::::::::::::E         //
//    V::::::V           V::::::V A:::::A             L:::::::::L             L:::::::::L             E::::::::::::::::::::E         //
//    V::::::V           V::::::VA:::::::A            LL:::::::LL             LL:::::::LL             EE::::::EEEEEEEEE::::E         //
//     V:::::V           V:::::VA:::::::::A             L:::::L                 L:::::L                 E:::::E       EEEEEE         //
//      V:::::V         V:::::VA:::::A:::::A            L:::::L                 L:::::L                 E:::::E                      //
//       V:::::V       V:::::VA:::::A A:::::A           L:::::L                 L:::::L                 E::::::EEEEEEEEEE            //
//        V:::::V     V:::::VA:::::A   A:::::A          L:::::L                 L:::::L                 E:::::::::::::::E            //
//         V:::::V   V:::::VA:::::A     A:::::A         L:::::L                 L:::::L                 E:::::::::::::::E            //
//          V:::::V V:::::VA:::::AAAAAAAAA:::::A        L:::::L                 L:::::L                 E::::::EEEEEEEEEE            //
//           V:::::V:::::VA:::::::::::::::::::::A       L:::::L                 L:::::L                 E:::::E                      //
//            V:::::::::VA:::::AAAAAAAAAAAAA:::::A      L:::::L         LLLLLL  L:::::L         LLLLLL  E:::::E       EEEEEE         //
//             V:::::::VA:::::A             A:::::A   LL:::::::LLLLLLLLL:::::LLL:::::::LLLLLLLLL:::::LEE::::::EEEEEEEE:::::E         //
//              V:::::VA:::::A               A:::::A  L::::::::::::::::::::::LL::::::::::::::::::::::LE::::::::::::::::::::E         //
//               V:::VA:::::A                 A:::::A L::::::::::::::::::::::LL::::::::::::::::::::::LE::::::::::::::::::::E         //
//                VVVAAAAAAA                   AAAAAAALLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLEEEEEEEEEEEEEEEEEEEEEE         //
//                                                                                                                                   //
//                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ADVALLE is ERC721Creator {
    constructor() ERC721Creator("Aimee Del Valle", "ADVALLE") {}
}