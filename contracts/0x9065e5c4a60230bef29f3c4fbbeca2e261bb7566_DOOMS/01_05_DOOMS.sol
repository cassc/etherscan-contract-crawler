// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DOOMSDAY
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//    DDDDDDDDDDDDD             OOOOOOOOO          OOOOOOOOO     MMMMMMMM               MMMMMMMM   SSSSSSSSSSSSSSS DDDDDDDDDDDDD                  AAA           YYYYYYY       YYYYYYY    //
//    D::::::::::::DDD        OO:::::::::OO      OO:::::::::OO   M:::::::M             M:::::::M SS:::::::::::::::SD::::::::::::DDD              A:::A          Y:::::Y       Y:::::Y    //
//    D:::::::::::::::DD    OO:::::::::::::OO  OO:::::::::::::OO M::::::::M           M::::::::MS:::::SSSSSS::::::SD:::::::::::::::DD           A:::::A         Y:::::Y       Y:::::Y    //
//    DDD:::::DDDDD:::::D  O:::::::OOO:::::::OO:::::::OOO:::::::OM:::::::::M         M:::::::::MS:::::S     SSSSSSSDDD:::::DDDDD:::::D         A:::::::A        Y::::::Y     Y::::::Y    //
//      D:::::D    D:::::D O::::::O   O::::::OO::::::O   O::::::OM::::::::::M       M::::::::::MS:::::S              D:::::D    D:::::D       A:::::::::A       YYY:::::Y   Y:::::YYY    //
//      D:::::D     D:::::DO:::::O     O:::::OO:::::O     O:::::OM:::::::::::M     M:::::::::::MS:::::S              D:::::D     D:::::D     A:::::A:::::A         Y:::::Y Y:::::Y       //
//      D:::::D     D:::::DO:::::O     O:::::OO:::::O     O:::::OM:::::::M::::M   M::::M:::::::M S::::SSSS           D:::::D     D:::::D    A:::::A A:::::A         Y:::::Y:::::Y        //
//      D:::::D     D:::::DO:::::O     O:::::OO:::::O     O:::::OM::::::M M::::M M::::M M::::::M  SS::::::SSSSS      D:::::D     D:::::D   A:::::A   A:::::A         Y:::::::::Y         //
//      D:::::D     D:::::DO:::::O     O:::::OO:::::O     O:::::OM::::::M  M::::M::::M  M::::::M    SSS::::::::SS    D:::::D     D:::::D  A:::::A     A:::::A         Y:::::::Y          //
//      D:::::D     D:::::DO:::::O     O:::::OO:::::O     O:::::OM::::::M   M:::::::M   M::::::M       SSSSSS::::S   D:::::D     D:::::D A:::::AAAAAAAAA:::::A         Y:::::Y           //
//      D:::::D     D:::::DO:::::O     O:::::OO:::::O     O:::::OM::::::M    M:::::M    M::::::M            S:::::S  D:::::D     D:::::DA:::::::::::::::::::::A        Y:::::Y           //
//      D:::::D    D:::::D O::::::O   O::::::OO::::::O   O::::::OM::::::M     MMMMM     M::::::M            S:::::S  D:::::D    D:::::DA:::::AAAAAAAAAAAAA:::::A       Y:::::Y           //
//    DDD:::::DDDDD:::::D  O:::::::OOO:::::::OO:::::::OOO:::::::OM::::::M               M::::::MSSSSSSS     S:::::SDDD:::::DDDDD:::::DA:::::A             A:::::A      Y:::::Y           //
//    D:::::::::::::::DD    OO:::::::::::::OO  OO:::::::::::::OO M::::::M               M::::::MS::::::SSSSSS:::::SD:::::::::::::::DDA:::::A               A:::::A  YYYY:::::YYYY        //
//    D::::::::::::DDD        OO:::::::::OO      OO:::::::::OO   M::::::M               M::::::MS:::::::::::::::SS D::::::::::::DDD A:::::A                 A:::::A Y:::::::::::Y        //
//    DDDDDDDDDDDDD             OOOOOOOOO          OOOOOOOOO     MMMMMMMM               MMMMMMMM SSSSSSSSSSSSSSS   DDDDDDDDDDDDD   AAAAAAA                   AAAAAAAYYYYYYYYYYYYY        //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
//                                                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DOOMS is ERC721Creator {
    constructor() ERC721Creator("DOOMSDAY", "DOOMS") {}
}