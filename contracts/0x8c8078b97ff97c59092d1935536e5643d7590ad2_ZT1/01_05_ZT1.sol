// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Zamunda Test 1
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//    ZZZZZZZZZZZZZZZZZZZ               AAA               MMMMMMMM               MMMMMMMMUUUUUUUU     UUUUUUUUNNNNNNNN        NNNNNNNNDDDDDDDDDDDDD                  AAA                   //
//    Z:::::::::::::::::Z              A:::A              M:::::::M             M:::::::MU::::::U     U::::::UN:::::::N       N::::::ND::::::::::::DDD              A:::A                  //
//    Z:::::::::::::::::Z             A:::::A             M::::::::M           M::::::::MU::::::U     U::::::UN::::::::N      N::::::ND:::::::::::::::DD           A:::::A                 //
//    Z:::ZZZZZZZZ:::::Z             A:::::::A            M:::::::::M         M:::::::::MUU:::::U     U:::::UUN:::::::::N     N::::::NDDD:::::DDDDD:::::D         A:::::::A                //
//    ZZZZZ     Z:::::Z             A:::::::::A           M::::::::::M       M::::::::::M U:::::U     U:::::U N::::::::::N    N::::::N  D:::::D    D:::::D       A:::::::::A               //
//            Z:::::Z              A:::::A:::::A          M:::::::::::M     M:::::::::::M U:::::D     D:::::U N:::::::::::N   N::::::N  D:::::D     D:::::D     A:::::A:::::A              //
//           Z:::::Z              A:::::A A:::::A         M:::::::M::::M   M::::M:::::::M U:::::D     D:::::U N:::::::N::::N  N::::::N  D:::::D     D:::::D    A:::::A A:::::A             //
//          Z:::::Z              A:::::A   A:::::A        M::::::M M::::M M::::M M::::::M U:::::D     D:::::U N::::::N N::::N N::::::N  D:::::D     D:::::D   A:::::A   A:::::A            //
//         Z:::::Z              A:::::A     A:::::A       M::::::M  M::::M::::M  M::::::M U:::::D     D:::::U N::::::N  N::::N:::::::N  D:::::D     D:::::D  A:::::A     A:::::A           //
//        Z:::::Z              A:::::AAAAAAAAA:::::A      M::::::M   M:::::::M   M::::::M U:::::D     D:::::U N::::::N   N:::::::::::N  D:::::D     D:::::D A:::::AAAAAAAAA:::::A          //
//       Z:::::Z              A:::::::::::::::::::::A     M::::::M    M:::::M    M::::::M U:::::D     D:::::U N::::::N    N::::::::::N  D:::::D     D:::::DA:::::::::::::::::::::A         //
//    ZZZ:::::Z     ZZZZZ    A:::::AAAAAAAAAAAAA:::::A    M::::::M     MMMMM     M::::::M U::::::U   U::::::U N::::::N     N:::::::::N  D:::::D    D:::::DA:::::AAAAAAAAAAAAA:::::A        //
//    Z::::::ZZZZZZZZ:::Z   A:::::A             A:::::A   M::::::M               M::::::M U:::::::UUU:::::::U N::::::N      N::::::::NDDD:::::DDDDD:::::DA:::::A             A:::::A       //
//    Z:::::::::::::::::Z  A:::::A               A:::::A  M::::::M               M::::::M  UU:::::::::::::UU  N::::::N       N:::::::ND:::::::::::::::DDA:::::A               A:::::A      //
//    Z:::::::::::::::::Z A:::::A                 A:::::A M::::::M               M::::::M    UU:::::::::UU    N::::::N        N::::::ND::::::::::::DDD A:::::A                 A:::::A     //
//    ZZZZZZZZZZZZZZZZZZZAAAAAAA                   AAAAAAAMMMMMMMM               MMMMMMMM      UUUUUUUUU      NNNNNNNN         NNNNNNNDDDDDDDDDDDDD   AAAAAAA                   AAAAAAA    //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ZT1 is ERC1155Creator {
    constructor() ERC1155Creator("Zamunda Test 1", "ZT1") {}
}