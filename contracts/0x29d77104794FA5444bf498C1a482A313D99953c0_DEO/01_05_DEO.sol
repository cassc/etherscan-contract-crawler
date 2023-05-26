// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DEODATO.io
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                       //
//                                                                                                                                                                                                       //
//                                                                                                                                                                                                       //
//                                                                                                                                                                                                       //
//                                                                                                                                                                                                       //
//    DDDDDDDDDDDDD        EEEEEEEEEEEEEEEEEEEEEE     OOOOOOOOO     DDDDDDDDDDDDD                       AAA               TTTTTTTTTTTTTTTTTTTTTTT     OOOOOOOOO               iiii                       //
//    D::::::::::::DDD     E::::::::::::::::::::E   OO:::::::::OO   D::::::::::::DDD                   A:::A              T:::::::::::::::::::::T   OO:::::::::OO            i::::i                      //
//    D:::::::::::::::DD   E::::::::::::::::::::E OO:::::::::::::OO D:::::::::::::::DD                A:::::A             T:::::::::::::::::::::T OO:::::::::::::OO           iiii                       //
//    DDD:::::DDDDD:::::D  EE::::::EEEEEEEEE::::EO:::::::OOO:::::::ODDD:::::DDDDD:::::D              A:::::::A            T:::::TT:::::::TT:::::TO:::::::OOO:::::::O                                     //
//      D:::::D    D:::::D   E:::::E       EEEEEEO::::::O   O::::::O  D:::::D    D:::::D            A:::::::::A           TTTTTT  T:::::T  TTTTTTO::::::O   O::::::O        iiiiiii    ooooooooooo       //
//      D:::::D     D:::::D  E:::::E             O:::::O     O:::::O  D:::::D     D:::::D          A:::::A:::::A                  T:::::T        O:::::O     O:::::O        i:::::i  oo:::::::::::oo     //
//      D:::::D     D:::::D  E::::::EEEEEEEEEE   O:::::O     O:::::O  D:::::D     D:::::D         A:::::A A:::::A                 T:::::T        O:::::O     O:::::O         i::::i o:::::::::::::::o    //
//      D:::::D     D:::::D  E:::::::::::::::E   O:::::O     O:::::O  D:::::D     D:::::D        A:::::A   A:::::A                T:::::T        O:::::O     O:::::O         i::::i o:::::ooooo:::::o    //
//      D:::::D     D:::::D  E:::::::::::::::E   O:::::O     O:::::O  D:::::D     D:::::D       A:::::A     A:::::A               T:::::T        O:::::O     O:::::O         i::::i o::::o     o::::o    //
//      D:::::D     D:::::D  E::::::EEEEEEEEEE   O:::::O     O:::::O  D:::::D     D:::::D      A:::::AAAAAAAAA:::::A              T:::::T        O:::::O     O:::::O         i::::i o::::o     o::::o    //
//      D:::::D     D:::::D  E:::::E             O:::::O     O:::::O  D:::::D     D:::::D     A:::::::::::::::::::::A             T:::::T        O:::::O     O:::::O         i::::i o::::o     o::::o    //
//      D:::::D    D:::::D   E:::::E       EEEEEEO::::::O   O::::::O  D:::::D    D:::::D     A:::::AAAAAAAAAAAAA:::::A            T:::::T        O::::::O   O::::::O         i::::i o::::o     o::::o    //
//    DDD:::::DDDDD:::::D  EE::::::EEEEEEEE:::::EO:::::::OOO:::::::ODDD:::::DDDDD:::::D     A:::::A             A:::::A         TT:::::::TT      O:::::::OOO:::::::O        i::::::io:::::ooooo:::::o    //
//    D:::::::::::::::DD   E::::::::::::::::::::E OO:::::::::::::OO D:::::::::::::::DD     A:::::A               A:::::A        T:::::::::T       OO:::::::::::::OO  ...... i::::::io:::::::::::::::o    //
//    D::::::::::::DDD     E::::::::::::::::::::E   OO:::::::::OO   D::::::::::::DDD      A:::::A                 A:::::A       T:::::::::T         OO:::::::::OO    .::::. i::::::i oo:::::::::::oo     //
//    DDDDDDDDDDDDD        EEEEEEEEEEEEEEEEEEEEEE     OOOOOOOOO     DDDDDDDDDDDDD        AAAAAAA                   AAAAAAA      TTTTTTTTTTT           OOOOOOOOO      ...... iiiiiiii   ooooooooooo       //
//                                                                                                                                                                                                       //
//                                                                                                                                                                                                       //
//                                                                                                                                                                                                       //
//                                                                                                                                                                                                       //
//                                                                                                                                                                                                       //
//                                                                                                                                                                                                       //
//                                                                                                                                                                                                       //
//                                                                                                                                                                                                       //
//                                                                                                                                                                                                       //
//                                                                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DEO is ERC721Creator {
    constructor() ERC721Creator("DEODATO.io", "DEO") {}
}