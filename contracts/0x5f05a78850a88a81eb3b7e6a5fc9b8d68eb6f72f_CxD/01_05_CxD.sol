// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CRAVE x Dragaan
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//            CCCCCCCCCCCCCRRRRRRRRRRRRRRRRR                  AAA   VVVVVVVV           VVVVVVVVEEEEEEEEEEEEEEEEEEEEEE                         ///////                    ///////            //
//         CCC::::::::::::CR::::::::::::::::R                A:::A  V::::::V           V::::::VE::::::::::::::::::::E                        /:::::/                    /:::::/             //
//       CC:::::::::::::::CR::::::RRRRRR:::::R              A:::::A V::::::V           V::::::VE::::::::::::::::::::E                       /:::::/                    /:::::/              //
//      C:::::CCCCCCCC::::CRR:::::R     R:::::R            A:::::::AV::::::V           V::::::VEE::::::EEEEEEEEE::::E                      /:::::/                    /:::::/               //
//     C:::::C       CCCCCC  R::::R     R:::::R           A:::::::::AV:::::V           V:::::V   E:::::E       EEEEEE                     /:::::/                    /:::::/                //
//    C:::::C                R::::R     R:::::R          A:::::A:::::AV:::::V         V:::::V    E:::::E                                 /:::::/                    /:::::/                 //
//    C:::::C                R::::RRRRRR:::::R          A:::::A A:::::AV:::::V       V:::::V     E::::::EEEEEEEEEE                      /:::::/                    /:::::/                  //
//    C:::::C                R:::::::::::::RR          A:::::A   A:::::AV:::::V     V:::::V      E:::::::::::::::E                     /:::::/                    /:::::/                   //
//    C:::::C                R::::RRRRRR:::::R        A:::::A     A:::::AV:::::V   V:::::V       E:::::::::::::::E                    /:::::/                    /:::::/                    //
//    C:::::C                R::::R     R:::::R      A:::::AAAAAAAAA:::::AV:::::V V:::::V        E::::::EEEEEEEEEE                   /:::::/                    /:::::/                     //
//    C:::::C                R::::R     R:::::R     A:::::::::::::::::::::AV:::::V:::::V         E:::::E                            /:::::/                    /:::::/                      //
//     C:::::C       CCCCCC  R::::R     R:::::R    A:::::AAAAAAAAAAAAA:::::AV:::::::::V          E:::::E       EEEEEE              /:::::/                    /:::::/                       //
//      C:::::CCCCCCCC::::CRR:::::R     R:::::R   A:::::A             A:::::AV:::::::V         EE::::::EEEEEEEE:::::E             /:::::/                    /:::::/                        //
//       CC:::::::::::::::CR::::::R     R:::::R  A:::::A               A:::::AV:::::V          E::::::::::::::::::::E            /:::::/                    /:::::/                         //
//         CCC::::::::::::CR::::::R     R:::::R A:::::A                 A:::::AV:::V           E::::::::::::::::::::E           /:::::/                    /:::::/                          //
//            CCCCCCCCCCCCCRRRRRRRR     RRRRRRRAAAAAAA                   AAAAAAAVVV            EEEEEEEEEEEEEEEEEEEEEE          ///////                    ///////                           //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//    DDDDDDDDDDDDD      RRRRRRRRRRRRRRRRR                  AAA                  GGGGGGGGGGGGG               AAA                              AAA               NNNNNNNN        NNNNNNNN    //
//    D::::::::::::DDD   R::::::::::::::::R                A:::A              GGG::::::::::::G              A:::A                            A:::A              N:::::::N       N::::::N    //
//    D:::::::::::::::DD R::::::RRRRRR:::::R              A:::::A           GG:::::::::::::::G             A:::::A                          A:::::A             N::::::::N      N::::::N    //
//    DDD:::::DDDDD:::::DRR:::::R     R:::::R            A:::::::A         G:::::GGGGGGGG::::G            A:::::::A                        A:::::::A            N:::::::::N     N::::::N    //
//      D:::::D    D:::::D R::::R     R:::::R           A:::::::::A       G:::::G       GGGGGG           A:::::::::A                      A:::::::::A           N::::::::::N    N::::::N    //
//      D:::::D     D:::::DR::::R     R:::::R          A:::::A:::::A     G:::::G                        A:::::A:::::A                    A:::::A:::::A          N:::::::::::N   N::::::N    //
//      D:::::D     D:::::DR::::RRRRRR:::::R          A:::::A A:::::A    G:::::G                       A:::::A A:::::A                  A:::::A A:::::A         N:::::::N::::N  N::::::N    //
//      D:::::D     D:::::DR:::::::::::::RR          A:::::A   A:::::A   G:::::G    GGGGGGGGGG        A:::::A   A:::::A                A:::::A   A:::::A        N::::::N N::::N N::::::N    //
//      D:::::D     D:::::DR::::RRRRRR:::::R        A:::::A     A:::::A  G:::::G    G::::::::G       A:::::A     A:::::A              A:::::A     A:::::A       N::::::N  N::::N:::::::N    //
//      D:::::D     D:::::DR::::R     R:::::R      A:::::AAAAAAAAA:::::A G:::::G    GGGGG::::G      A:::::AAAAAAAAA:::::A            A:::::AAAAAAAAA:::::A      N::::::N   N:::::::::::N    //
//      D:::::D     D:::::DR::::R     R:::::R     A:::::::::::::::::::::AG:::::G        G::::G     A:::::::::::::::::::::A          A:::::::::::::::::::::A     N::::::N    N::::::::::N    //
//      D:::::D    D:::::D R::::R     R:::::R    A:::::AAAAAAAAAAAAA:::::AG:::::G       G::::G    A:::::AAAAAAAAAAAAA:::::A        A:::::AAAAAAAAAAAAA:::::A    N::::::N     N:::::::::N    //
//    DDD:::::DDDDD:::::DRR:::::R     R:::::R   A:::::A             A:::::AG:::::GGGGGGGG::::G   A:::::A             A:::::A      A:::::A             A:::::A   N::::::N      N::::::::N    //
//    D:::::::::::::::DD R::::::R     R:::::R  A:::::A               A:::::AGG:::::::::::::::G  A:::::A               A:::::A    A:::::A               A:::::A  N::::::N       N:::::::N    //
//    D::::::::::::DDD   R::::::R     R:::::R A:::::A                 A:::::A GGG::::::GGG:::G A:::::A                 A:::::A  A:::::A                 A:::::A N::::::N        N::::::N    //
//    DDDDDDDDDDDDD      RRRRRRRR     RRRRRRRAAAAAAA                   AAAAAAA   GGGGGG   GGGGAAAAAAA                   AAAAAAAAAAAAAA                   AAAAAAANNNNNNNN         NNNNNNN    //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//                                                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CxD is ERC721Creator {
    constructor() ERC721Creator("CRAVE x Dragaan", "CxD") {}
}