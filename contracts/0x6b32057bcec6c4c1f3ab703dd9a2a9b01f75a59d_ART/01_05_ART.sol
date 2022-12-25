// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ARTICULATE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                   AAA               RRRRRRRRRRRRRRRRR   TTTTTTTTTTTTTTTTTTTTTTT         //
//                  A:::A              R::::::::::::::::R  T:::::::::::::::::::::T         //
//                 A:::::A             R::::::RRRRRR:::::R T:::::::::::::::::::::T         //
//                A:::::::A            RR:::::R     R:::::RT:::::TT:::::::TT:::::T         //
//               A:::::::::A             R::::R     R:::::RTTTTTT  T:::::T  TTTTTT         //
//              A:::::A:::::A            R::::R     R:::::R        T:::::T                 //
//             A:::::A A:::::A           R::::RRRRRR:::::R         T:::::T                 //
//            A:::::A   A:::::A          R:::::::::::::RR          T:::::T                 //
//           A:::::A     A:::::A         R::::RRRRRR:::::R         T:::::T                 //
//          A:::::AAAAAAAAA:::::A        R::::R     R:::::R        T:::::T                 //
//         A:::::::::::::::::::::A       R::::R     R:::::R        T:::::T                 //
//        A:::::AAAAAAAAAAAAA:::::A      R::::R     R:::::R        T:::::T                 //
//       A:::::A             A:::::A   RR:::::R     R:::::R      TT:::::::TT               //
//      A:::::A               A:::::A  R::::::R     R:::::R      T:::::::::T               //
//     A:::::A                 A:::::A R::::::R     R:::::R      T:::::::::T               //
//    AAAAAAA                   AAAAAAARRRRRRRR     RRRRRRR      TTTTTTTTTTT               //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////


contract ART is ERC721Creator {
    constructor() ERC721Creator("ARTICULATE", "ART") {}
}