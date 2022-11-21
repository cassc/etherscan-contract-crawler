// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Avatares
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//                   AAA   VVVVVVVV           VVVVVVVV   AAA         TTTTTTTTTTTTTTTTTTTTTTT         AAA               RRRRRRRRRRRRRRRRR   EEEEEEEEEEEEEEEEEEEEEE   SSSSSSSSSSSSSSS                          //
//                  A:::A  V::::::V           V::::::V  A:::A        T:::::::::::::::::::::T        A:::A              R::::::::::::::::R  E::::::::::::::::::::E SS:::::::::::::::S                         //
//                 A:::::A V::::::V           V::::::V A:::::A       T:::::::::::::::::::::T       A:::::A             R::::::RRRRRR:::::R E::::::::::::::::::::ES:::::SSSSSS::::::S                         //
//                A:::::::AV::::::V           V::::::VA:::::::A      T:::::TT:::::::TT:::::T      A:::::::A            RR:::::R     R:::::REE::::::EEEEEEEEE::::ES:::::S     SSSSSSS                         //
//               A:::::::::AV:::::V           V:::::VA:::::::::A     TTTTTT  T:::::T  TTTTTT     A:::::::::A             R::::R     R:::::R  E:::::E       EEEEEES:::::S                                     //
//              A:::::A:::::AV:::::V         V:::::VA:::::A:::::A            T:::::T            A:::::A:::::A            R::::R     R:::::R  E:::::E             S:::::S                                     //
//             A:::::A A:::::AV:::::V       V:::::VA:::::A A:::::A           T:::::T           A:::::A A:::::A           R::::RRRRRR:::::R   E::::::EEEEEEEEEE    S::::SSSS                                  //
//            A:::::A   A:::::AV:::::V     V:::::VA:::::A   A:::::A          T:::::T          A:::::A   A:::::A          R:::::::::::::RR    E:::::::::::::::E     SS::::::SSSSS                             //
//           A:::::A     A:::::AV:::::V   V:::::VA:::::A     A:::::A         T:::::T         A:::::A     A:::::A         R::::RRRRRR:::::R   E:::::::::::::::E       SSS::::::::SS                           //
//          A:::::AAAAAAAAA:::::AV:::::V V:::::VA:::::AAAAAAAAA:::::A        T:::::T        A:::::AAAAAAAAA:::::A        R::::R     R:::::R  E::::::EEEEEEEEEE          SSSSSS::::S                          //
//         A:::::::::::::::::::::AV:::::V:::::VA:::::::::::::::::::::A       T:::::T       A:::::::::::::::::::::A       R::::R     R:::::R  E:::::E                         S:::::S                         //
//        A:::::AAAAAAAAAAAAA:::::AV:::::::::VA:::::AAAAAAAAAAAAA:::::A      T:::::T      A:::::AAAAAAAAAAAAA:::::A      R::::R     R:::::R  E:::::E       EEEEEE            S:::::S                         //
//       A:::::A             A:::::AV:::::::VA:::::A             A:::::A   TT:::::::TT   A:::::A             A:::::A   RR:::::R     R:::::REE::::::EEEEEEEE:::::ESSSSSSS     S:::::S                         //
//      A:::::A               A:::::AV:::::VA:::::A               A:::::A  T:::::::::T  A:::::A               A:::::A  R::::::R     R:::::RE::::::::::::::::::::ES::::::SSSSSS:::::S                         //
//     A:::::A                 A:::::AV:::VA:::::A                 A:::::A T:::::::::T A:::::A                 A:::::A R::::::R     R:::::RE::::::::::::::::::::ES:::::::::::::::SS                          //
//    AAAAAAA                   AAAAAAAVVVAAAAAAA                   AAAAAAATTTTTTTTTTTAAAAAAA                   AAAAAAARRRRRRRR     RRRRRRREEEEEEEEEEEEEEEEEEEEEE SSSSSSSSSSSSSSS                            //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
//     A CC Project by aissa                                                                                                                                                                                 //
//                                                                                                                                                                                                           //
//                                                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AV is ERC721Creator {
    constructor() ERC721Creator("Avatares", "AV") {}
}