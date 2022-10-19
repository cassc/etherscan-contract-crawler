// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Submerged - Big Magenta
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//    BBBBBBBBBBBBBBBBB   IIIIIIIIII      GGGGGGGGGGGGG     MMMMMMMM               MMMMMMMM               AAA                  GGGGGGGGGGGGGEEEEEEEEEEEEEEEEEEEEEENNNNNNNN        NNNNNNNNTTTTTTTTTTTTTTTTTTTTTTT         AAA                   //
//    B::::::::::::::::B  I::::::::I   GGG::::::::::::G     M:::::::M             M:::::::M              A:::A              GGG::::::::::::GE::::::::::::::::::::EN:::::::N       N::::::NT:::::::::::::::::::::T        A:::A                  //
//    B::::::BBBBBB:::::B I::::::::I GG:::::::::::::::G     M::::::::M           M::::::::M             A:::::A           GG:::::::::::::::GE::::::::::::::::::::EN::::::::N      N::::::NT:::::::::::::::::::::T       A:::::A                 //
//    BB:::::B     B:::::BII::::::IIG:::::GGGGGGGG::::G     M:::::::::M         M:::::::::M            A:::::::A         G:::::GGGGGGGG::::GEE::::::EEEEEEEEE::::EN:::::::::N     N::::::NT:::::TT:::::::TT:::::T      A:::::::A                //
//      B::::B     B:::::B  I::::I G:::::G       GGGGGG     M::::::::::M       M::::::::::M           A:::::::::A       G:::::G       GGGGGG  E:::::E       EEEEEEN::::::::::N    N::::::NTTTTTT  T:::::T  TTTTTT     A:::::::::A               //
//      B::::B     B:::::B  I::::IG:::::G                   M:::::::::::M     M:::::::::::M          A:::::A:::::A     G:::::G                E:::::E             N:::::::::::N   N::::::N        T:::::T            A:::::A:::::A              //
//      B::::BBBBBB:::::B   I::::IG:::::G                   M:::::::M::::M   M::::M:::::::M         A:::::A A:::::A    G:::::G                E::::::EEEEEEEEEE   N:::::::N::::N  N::::::N        T:::::T           A:::::A A:::::A             //
//      B:::::::::::::BB    I::::IG:::::G    GGGGGGGGGG     M::::::M M::::M M::::M M::::::M        A:::::A   A:::::A   G:::::G    GGGGGGGGGG  E:::::::::::::::E   N::::::N N::::N N::::::N        T:::::T          A:::::A   A:::::A            //
//      B::::BBBBBB:::::B   I::::IG:::::G    G::::::::G     M::::::M  M::::M::::M  M::::::M       A:::::A     A:::::A  G:::::G    G::::::::G  E:::::::::::::::E   N::::::N  N::::N:::::::N        T:::::T         A:::::A     A:::::A           //
//      B::::B     B:::::B  I::::IG:::::G    GGGGG::::G     M::::::M   M:::::::M   M::::::M      A:::::AAAAAAAAA:::::A G:::::G    GGGGG::::G  E::::::EEEEEEEEEE   N::::::N   N:::::::::::N        T:::::T        A:::::AAAAAAAAA:::::A          //
//      B::::B     B:::::B  I::::IG:::::G        G::::G     M::::::M    M:::::M    M::::::M     A:::::::::::::::::::::AG:::::G        G::::G  E:::::E             N::::::N    N::::::::::N        T:::::T       A:::::::::::::::::::::A         //
//      B::::B     B:::::B  I::::I G:::::G       G::::G     M::::::M     MMMMM     M::::::M    A:::::AAAAAAAAAAAAA:::::AG:::::G       G::::G  E:::::E       EEEEEEN::::::N     N:::::::::N        T:::::T      A:::::AAAAAAAAAAAAA:::::A        //
//    BB:::::BBBBBB::::::BII::::::IIG:::::GGGGGGGG::::G     M::::::M               M::::::M   A:::::A             A:::::AG:::::GGGGGGGG::::GEE::::::EEEEEEEE:::::EN::::::N      N::::::::N      TT:::::::TT   A:::::A             A:::::A       //
//    B:::::::::::::::::B I::::::::I GG:::::::::::::::G     M::::::M               M::::::M  A:::::A               A:::::AGG:::::::::::::::GE::::::::::::::::::::EN::::::N       N:::::::N      T:::::::::T  A:::::A               A:::::A      //
//    B::::::::::::::::B  I::::::::I   GGG::::::GGG:::G     M::::::M               M::::::M A:::::A                 A:::::A GGG::::::GGG:::GE::::::::::::::::::::EN::::::N        N::::::N      T:::::::::T A:::::A                 A:::::A     //
//    BBBBBBBBBBBBBBBBB   IIIIIIIIII      GGGGGG   GGGG     MMMMMMMM               MMMMMMMMAAAAAAA                   AAAAAAA   GGGGGG   GGGGEEEEEEEEEEEEEEEEEEEEEENNNNNNNN         NNNNNNN      TTTTTTTTTTTAAAAAAA                   AAAAAAA    //
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SBM is ERC721Creator {
    constructor() ERC721Creator("Submerged - Big Magenta", "SBM") {}
}