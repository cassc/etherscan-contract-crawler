// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VolleyDAO x AVP Championships
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                           //
//                                                                                                                                                                           //
//                                                                                                                                                                           //
//                                                                                                                                                                           //
//    VVVVVVVV           VVVVVVVV              lllllll lllllll                                          DDDDDDDDDDDDD                  AAA                 OOOOOOOOO         //
//    V::::::V           V::::::V              l:::::l l:::::l                                          D::::::::::::DDD              A:::A              OO:::::::::OO       //
//    V::::::V           V::::::V              l:::::l l:::::l                                          D:::::::::::::::DD           A:::::A           OO:::::::::::::OO     //
//    V::::::V           V::::::V              l:::::l l:::::l                                          DDD:::::DDDDD:::::D         A:::::::A         O:::::::OOO:::::::O    //
//     V:::::V           V:::::V ooooooooooo    l::::l  l::::l     eeeeeeeeeeee  yyyyyyy           yyyyyyyD:::::D    D:::::D       A:::::::::A        O::::::O   O::::::O    //
//      V:::::V         V:::::Voo:::::::::::oo  l::::l  l::::l   ee::::::::::::ee y:::::y         y:::::y D:::::D     D:::::D     A:::::A:::::A       O:::::O     O:::::O    //
//       V:::::V       V:::::Vo:::::::::::::::o l::::l  l::::l  e::::::eeeee:::::eey:::::y       y:::::y  D:::::D     D:::::D    A:::::A A:::::A      O:::::O     O:::::O    //
//        V:::::V     V:::::V o:::::ooooo:::::o l::::l  l::::l e::::::e     e:::::e y:::::y     y:::::y   D:::::D     D:::::D   A:::::A   A:::::A     O:::::O     O:::::O    //
//         V:::::V   V:::::V  o::::o     o::::o l::::l  l::::l e:::::::eeeee::::::e  y:::::y   y:::::y    D:::::D     D:::::D  A:::::A     A:::::A    O:::::O     O:::::O    //
//          V:::::V V:::::V   o::::o     o::::o l::::l  l::::l e:::::::::::::::::e    y:::::y y:::::y     D:::::D     D:::::D A:::::AAAAAAAAA:::::A   O:::::O     O:::::O    //
//           V:::::V:::::V    o::::o     o::::o l::::l  l::::l e::::::eeeeeeeeeee      y:::::y:::::y      D:::::D     D:::::DA:::::::::::::::::::::A  O:::::O     O:::::O    //
//            V:::::::::V     o::::o     o::::o l::::l  l::::l e:::::::e                y:::::::::y       D:::::D    D:::::DA:::::AAAAAAAAAAAAA:::::A O::::::O   O::::::O    //
//             V:::::::V      o:::::ooooo:::::ol::::::ll::::::le::::::::e                y:::::::y      DDD:::::DDDDD:::::DA:::::A             A:::::AO:::::::OOO:::::::O    //
//              V:::::V       o:::::::::::::::ol::::::ll::::::l e::::::::eeeeeeee         y:::::y       D:::::::::::::::DDA:::::A               A:::::AOO:::::::::::::OO     //
//               V:::V         oo:::::::::::oo l::::::ll::::::l  ee:::::::::::::e        y:::::y        D::::::::::::DDD A:::::A                 A:::::A OO:::::::::OO       //
//                VVV            ooooooooooo   llllllllllllllll    eeeeeeeeeeeeee       y:::::y         DDDDDDDDDDDDD   AAAAAAA                   AAAAAAA  OOOOOOOOO         //
//                                                                                     y:::::y                                                                               //
//                                                                                    y:::::y                                                                                //
//                                                                                   y:::::y                                                                                 //
//                                                                                  y:::::y                                                                                  //
//                                                                                 yyyyyyy                                                                                   //
//                                                                                                                                                                           //
//                                                                                                                                                                           //
//                                                                                                                                                                           //
//                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VolleyDAOxAVP is ERC721Creator {
    constructor() ERC721Creator("VolleyDAO x AVP Championships", "VolleyDAOxAVP") {}
}