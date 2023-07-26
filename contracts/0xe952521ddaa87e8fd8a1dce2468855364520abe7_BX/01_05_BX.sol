// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BEXTA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                         //
//                                                                                                                         //
//    BBBBBBBBBBBBBBBBB   EEEEEEEEEEEEEEEEEEEEEEXXXXXXX       XXXXXXXTTTTTTTTTTTTTTTTTTTTTTT         AAA                   //
//    B::::::::::::::::B  E::::::::::::::::::::EX:::::X       X:::::XT:::::::::::::::::::::T        A:::A                  //
//    B::::::BBBBBB:::::B E::::::::::::::::::::EX:::::X       X:::::XT:::::::::::::::::::::T       A:::::A                 //
//    BB:::::B     B:::::BEE::::::EEEEEEEEE::::EX::::::X     X::::::XT:::::TT:::::::TT:::::T      A:::::::A                //
//      B::::B     B:::::B  E:::::E       EEEEEEXXX:::::X   X:::::XXXTTTTTT  T:::::T  TTTTTT     A:::::::::A               //
//      B::::B     B:::::B  E:::::E                X:::::X X:::::X           T:::::T            A:::::A:::::A              //
//      B::::BBBBBB:::::B   E::::::EEEEEEEEEE       X:::::X:::::X            T:::::T           A:::::A A:::::A             //
//      B:::::::::::::BB    E:::::::::::::::E        X:::::::::X             T:::::T          A:::::A   A:::::A            //
//      B::::BBBBBB:::::B   E:::::::::::::::E        X:::::::::X             T:::::T         A:::::A     A:::::A           //
//      B::::B     B:::::B  E::::::EEEEEEEEEE       X:::::X:::::X            T:::::T        A:::::AAAAAAAAA:::::A          //
//      B::::B     B:::::B  E:::::E                X:::::X X:::::X           T:::::T       A:::::::::::::::::::::A         //
//      B::::B     B:::::B  E:::::E       EEEEEEXXX:::::X   X:::::XXX        T:::::T      A:::::AAAAAAAAAAAAA:::::A        //
//    BB:::::BBBBBB::::::BEE::::::EEEEEEEE:::::EX::::::X     X::::::X      TT:::::::TT   A:::::A             A:::::A       //
//    B:::::::::::::::::B E::::::::::::::::::::EX:::::X       X:::::X      T:::::::::T  A:::::A               A:::::A      //
//    B::::::::::::::::B  E::::::::::::::::::::EX:::::X       X:::::X      T:::::::::T A:::::A                 A:::::A     //
//    BBBBBBBBBBBBBBBBB   EEEEEEEEEEEEEEEEEEEEEEXXXXXXX       XXXXXXX      TTTTTTTTTTTAAAAAAA                   AAAAAAA    //
//                                                                                                                         //
//                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BX is ERC721Creator {
    constructor() ERC721Creator("BEXTA", "BX") {}
}