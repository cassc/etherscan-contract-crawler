// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Snipe DAO
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                //
//                                                                                                                                                                //
//                                                                                                                                                                //
//                                                                                                                                                                //
//                                                                                                                                                                //
//       SSSSSSSSSSSSSSS                   iiii                                              DDDDDDDDDDDDD                  AAA                 OOOOOOOOO         //
//     SS:::::::::::::::S                 i::::i                                             D::::::::::::DDD              A:::A              OO:::::::::OO       //
//    S:::::SSSSSS::::::S                  iiii                                              D:::::::::::::::DD           A:::::A           OO:::::::::::::OO     //
//    S:::::S     SSSSSSS                                                                    DDD:::::DDDDD:::::D         A:::::::A         O:::::::OOO:::::::O    //
//    S:::::S          nnnn  nnnnnnnn    iiiiiiippppp   ppppppppp       eeeeeeeeeeee           D:::::D    D:::::D       A:::::::::A        O::::::O   O::::::O    //
//    S:::::S          n:::nn::::::::nn  i:::::ip::::ppp:::::::::p    ee::::::::::::ee         D:::::D     D:::::D     A:::::A:::::A       O:::::O     O:::::O    //
//     S::::SSSS       n::::::::::::::nn  i::::ip:::::::::::::::::p  e::::::eeeee:::::ee       D:::::D     D:::::D    A:::::A A:::::A      O:::::O     O:::::O    //
//      SS::::::SSSSS  nn:::::::::::::::n i::::ipp::::::ppppp::::::pe::::::e     e:::::e       D:::::D     D:::::D   A:::::A   A:::::A     O:::::O     O:::::O    //
//        SSS::::::::SS  n:::::nnnn:::::n i::::i p:::::p     p:::::pe:::::::eeeee::::::e       D:::::D     D:::::D  A:::::A     A:::::A    O:::::O     O:::::O    //
//           SSSSSS::::S n::::n    n::::n i::::i p:::::p     p:::::pe:::::::::::::::::e        D:::::D     D:::::D A:::::AAAAAAAAA:::::A   O:::::O     O:::::O    //
//                S:::::Sn::::n    n::::n i::::i p:::::p     p:::::pe::::::eeeeeeeeeee         D:::::D     D:::::DA:::::::::::::::::::::A  O:::::O     O:::::O    //
//                S:::::Sn::::n    n::::n i::::i p:::::p    p::::::pe:::::::e                  D:::::D    D:::::DA:::::AAAAAAAAAAAAA:::::A O::::::O   O::::::O    //
//    SSSSSSS     S:::::Sn::::n    n::::ni::::::ip:::::ppppp:::::::pe::::::::e               DDD:::::DDDDD:::::DA:::::A             A:::::AO:::::::OOO:::::::O    //
//    S::::::SSSSSS:::::Sn::::n    n::::ni::::::ip::::::::::::::::p  e::::::::eeeeeeee       D:::::::::::::::DDA:::::A               A:::::AOO:::::::::::::OO     //
//    S:::::::::::::::SS n::::n    n::::ni::::::ip::::::::::::::pp    ee:::::::::::::e       D::::::::::::DDD A:::::A                 A:::::A OO:::::::::OO       //
//     SSSSSSSSSSSSSSS   nnnnnn    nnnnnniiiiiiiip::::::pppppppp        eeeeeeeeeeeeee       DDDDDDDDDDDDD   AAAAAAA                   AAAAAAA  OOOOOOOOO         //
//                                               p:::::p                                                                                                          //
//                                               p:::::p                                                                                                          //
//                                              p:::::::p                                                                                                         //
//                                              p:::::::p                                                                                                         //
//                                              p:::::::p                                                                                                         //
//                                              ppppppppp                                                                                                         //
//                                                                                                                                                                //
//                                                                                                                                                                //
//                                                                                                                                                                //
//                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MEMBER is ERC721Creator {
    constructor() ERC721Creator("Snipe DAO", "MEMBER") {}
}