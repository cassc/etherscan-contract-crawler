// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Extant
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//    EEEEEEEEEEEEEEEEEEEEEEXXXXXXX       XXXXXXXTTTTTTTTTTTTTTTTTTTTTTT         AAA               NNNNNNNN        NNNNNNNNTTTTTTTTTTTTTTTTTTTTTTT    //
//    E::::::::::::::::::::EX:::::X       X:::::XT:::::::::::::::::::::T        A:::A              N:::::::N       N::::::NT:::::::::::::::::::::T    //
//    E::::::::::::::::::::EX:::::X       X:::::XT:::::::::::::::::::::T       A:::::A             N::::::::N      N::::::NT:::::::::::::::::::::T    //
//    EE::::::EEEEEEEEE::::EX::::::X     X::::::XT:::::TT:::::::TT:::::T      A:::::::A            N:::::::::N     N::::::NT:::::TT:::::::TT:::::T    //
//      E:::::E       EEEEEEXXX:::::X   X:::::XXXTTTTTT  T:::::T  TTTTTT     A:::::::::A           N::::::::::N    N::::::NTTTTTT  T:::::T  TTTTTT    //
//      E:::::E                X:::::X X:::::X           T:::::T            A:::::A:::::A          N:::::::::::N   N::::::N        T:::::T            //
//      E::::::EEEEEEEEEE       X:::::X:::::X            T:::::T           A:::::A A:::::A         N:::::::N::::N  N::::::N        T:::::T            //
//      E:::::::::::::::E        X:::::::::X             T:::::T          A:::::A   A:::::A        N::::::N N::::N N::::::N        T:::::T            //
//      E:::::::::::::::E        X:::::::::X             T:::::T         A:::::A     A:::::A       N::::::N  N::::N:::::::N        T:::::T            //
//      E::::::EEEEEEEEEE       X:::::X:::::X            T:::::T        A:::::AAAAAAAAA:::::A      N::::::N   N:::::::::::N        T:::::T            //
//      E:::::E                X:::::X X:::::X           T:::::T       A:::::::::::::::::::::A     N::::::N    N::::::::::N        T:::::T            //
//      E:::::E       EEEEEEXXX:::::X   X:::::XXX        T:::::T      A:::::AAAAAAAAAAAAA:::::A    N::::::N     N:::::::::N        T:::::T            //
//    EE::::::EEEEEEEE:::::EX::::::X     X::::::X      TT:::::::TT   A:::::A             A:::::A   N::::::N      N::::::::N      TT:::::::TT          //
//    E::::::::::::::::::::EX:::::X       X:::::X      T:::::::::T  A:::::A               A:::::A  N::::::N       N:::::::N      T:::::::::T          //
//    E::::::::::::::::::::EX:::::X       X:::::X      T:::::::::T A:::::A                 A:::::A N::::::N        N::::::N      T:::::::::T          //
//    EEEEEEEEEEEEEEEEEEEEEEXXXXXXX       XXXXXXX      TTTTTTTTTTTAAAAAAA                   AAAAAAANNNNNNNN         NNNNNNN      TTTTTTTTTTT          //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Extant is ERC721Creator {
    constructor() ERC721Creator("Extant", "Extant") {}
}