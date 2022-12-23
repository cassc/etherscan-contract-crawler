// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ryba Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                  RRRRRRRRRRRRRRRRR   YYYYYYY       YYYYYYYBBBBBBBBBBBBBBBBB               AAA                                            //
//                                  R::::::::::::::::R  Y:::::Y       Y:::::YB::::::::::::::::B             A:::A                                           //
//                                  R::::::RRRRRR:::::R Y:::::Y       Y:::::YB::::::BBBBBB:::::B           A:::::A                                          //
//                                  RR:::::R     R:::::RY::::::Y     Y::::::YBB:::::B     B:::::B         A:::::::A                                         //
//                                    R::::R     R:::::RYYY:::::Y   Y:::::YYY  B::::B     B:::::B        A:::::::::A                                        //
//                                    R::::R     R:::::R   Y:::::Y Y:::::Y     B::::B     B:::::B       A:::::A:::::A                                       //
//                                    R::::RRRRRR:::::R     Y:::::Y:::::Y      B::::BBBBBB:::::B       A:::::A A:::::A                                      //
//                                    R:::::::::::::RR       Y:::::::::Y       B:::::::::::::BB       A:::::A   A:::::A                                     //
//                                    R::::RRRRRR:::::R       Y:::::::Y        B::::BBBBBB:::::B     A:::::A     A:::::A                                    //
//                                    R::::R     R:::::R       Y:::::Y         B::::B     B:::::B   A:::::AAAAAAAAA:::::A                                   //
//                                    R::::R     R:::::R       Y:::::Y         B::::B     B:::::B  A:::::::::::::::::::::A                                  //
//                                    R::::R     R:::::R       Y:::::Y         B::::B     B:::::B A:::::AAAAAAAAAAAAA:::::A                                 //
//                                  RR:::::R     R:::::R       Y:::::Y       BB:::::BBBBBB::::::BA:::::A             A:::::A                                //
//                                  R::::::R     R:::::R    YYYY:::::YYYY    B:::::::::::::::::BA:::::A               A:::::A                               //
//                                  R::::::R     R:::::R    Y:::::::::::Y    B::::::::::::::::BA:::::A                 A:::::A                              //
//                                  RRRRRRRR     RRRRRRR    YYYYYYYYYYYYY    BBBBBBBBBBBBBBBBBAAAAAAA                   AAAAAAA                             //
//                                                                                                                                                          //
//    EEEEEEEEEEEEEEEEEEEEEEDDDDDDDDDDDDD      IIIIIIIIIITTTTTTTTTTTTTTTTTTTTTTTIIIIIIIIII     OOOOOOOOO     NNNNNNNN        NNNNNNNN   SSSSSSSSSSSSSSS     //
//    E::::::::::::::::::::ED::::::::::::DDD   I::::::::IT:::::::::::::::::::::TI::::::::I   OO:::::::::OO   N:::::::N       N::::::N SS:::::::::::::::S    //
//    E::::::::::::::::::::ED:::::::::::::::DD I::::::::IT:::::::::::::::::::::TI::::::::I OO:::::::::::::OO N::::::::N      N::::::NS:::::SSSSSS::::::S    //
//    EE::::::EEEEEEEEE::::EDDD:::::DDDDD:::::DII::::::IIT:::::TT:::::::TT:::::TII::::::IIO:::::::OOO:::::::ON:::::::::N     N::::::NS:::::S     SSSSSSS    //
//      E:::::E       EEEEEE  D:::::D    D:::::D I::::I  TTTTTT  T:::::T  TTTTTT  I::::I  O::::::O   O::::::ON::::::::::N    N::::::NS:::::S                //
//      E:::::E               D:::::D     D:::::DI::::I          T:::::T          I::::I  O:::::O     O:::::ON:::::::::::N   N::::::NS:::::S                //
//      E::::::EEEEEEEEEE     D:::::D     D:::::DI::::I          T:::::T          I::::I  O:::::O     O:::::ON:::::::N::::N  N::::::N S::::SSSS             //
//      E:::::::::::::::E     D:::::D     D:::::DI::::I          T:::::T          I::::I  O:::::O     O:::::ON::::::N N::::N N::::::N  SS::::::SSSSS        //
//      E:::::::::::::::E     D:::::D     D:::::DI::::I          T:::::T          I::::I  O:::::O     O:::::ON::::::N  N::::N:::::::N    SSS::::::::SS      //
//      E::::::EEEEEEEEEE     D:::::D     D:::::DI::::I          T:::::T          I::::I  O:::::O     O:::::ON::::::N   N:::::::::::N       SSSSSS::::S     //
//      E:::::E               D:::::D     D:::::DI::::I          T:::::T          I::::I  O:::::O     O:::::ON::::::N    N::::::::::N            S:::::S    //
//      E:::::E       EEEEEE  D:::::D    D:::::D I::::I          T:::::T          I::::I  O::::::O   O::::::ON::::::N     N:::::::::N            S:::::S    //
//    EE::::::EEEEEEEE:::::EDDD:::::DDDDD:::::DII::::::II      TT:::::::TT      II::::::IIO:::::::OOO:::::::ON::::::N      N::::::::NSSSSSSS     S:::::S    //
//    E::::::::::::::::::::ED:::::::::::::::DD I::::::::I      T:::::::::T      I::::::::I OO:::::::::::::OO N::::::N       N:::::::NS::::::SSSSSS:::::S    //
//    E::::::::::::::::::::ED::::::::::::DDD   I::::::::I      T:::::::::T      I::::::::I   OO:::::::::OO   N::::::N        N::::::NS:::::::::::::::SS     //
//    EEEEEEEEEEEEEEEEEEEEEEDDDDDDDDDDDDD      IIIIIIIIII      TTTTTTTTTTT      IIIIIIIIII     OOOOOOOOO     NNNNNNNN         NNNNNNN SSSSSSSSSSSSSSS       //
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JREDI is ERC1155Creator {
    constructor() ERC1155Creator("Ryba Editions", "JREDI") {}
}