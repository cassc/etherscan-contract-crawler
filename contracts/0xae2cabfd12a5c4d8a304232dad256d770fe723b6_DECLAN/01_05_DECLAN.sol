// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DECLAN RMC
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                              //
//    DDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEE       CCCCCCCCCCCCCLLLLLLLLLLL                            AAA               NNNNNNNN        NNNNNNNNRRRRRRRRRRRRRRRRR   MMMMMMMM               MMMMMMMM        CCCCCCCCCCCCC    //
//    D::::::::::::DDD   E::::::::::::::::::::E    CCC::::::::::::CL:::::::::L                           A:::A              N:::::::N       N::::::NR::::::::::::::::R  M:::::::M             M:::::::M     CCC::::::::::::C    //
//    D:::::::::::::::DD E::::::::::::::::::::E  CC:::::::::::::::CL:::::::::L                          A:::::A             N::::::::N      N::::::NR::::::RRRRRR:::::R M::::::::M           M::::::::M   CC:::::::::::::::C    //
//    DDD:::::DDDDD:::::DEE::::::EEEEEEEEE::::E C:::::CCCCCCCC::::CLL:::::::LL                         A:::::::A            N:::::::::N     N::::::NRR:::::R     R:::::RM:::::::::M         M:::::::::M  C:::::CCCCCCCC::::C    //
//      D:::::D    D:::::D E:::::E       EEEEEEC:::::C       CCCCCC  L:::::L                          A:::::::::A           N::::::::::N    N::::::N  R::::R     R:::::RM::::::::::M       M::::::::::M C:::::C       CCCCCC    //
//      D:::::D     D:::::DE:::::E            C:::::C                L:::::L                         A:::::A:::::A          N:::::::::::N   N::::::N  R::::R     R:::::RM:::::::::::M     M:::::::::::MC:::::C                  //
//      D:::::D     D:::::DE::::::EEEEEEEEEE  C:::::C                L:::::L                        A:::::A A:::::A         N:::::::N::::N  N::::::N  R::::RRRRRR:::::R M:::::::M::::M   M::::M:::::::MC:::::C                  //
//      D:::::D     D:::::DE:::::::::::::::E  C:::::C                L:::::L                       A:::::A   A:::::A        N::::::N N::::N N::::::N  R:::::::::::::RR  M::::::M M::::M M::::M M::::::MC:::::C                  //
//      D:::::D     D:::::DE:::::::::::::::E  C:::::C                L:::::L                      A:::::A     A:::::A       N::::::N  N::::N:::::::N  R::::RRRRRR:::::R M::::::M  M::::M::::M  M::::::MC:::::C                  //
//      D:::::D     D:::::DE::::::EEEEEEEEEE  C:::::C                L:::::L                     A:::::AAAAAAAAA:::::A      N::::::N   N:::::::::::N  R::::R     R:::::RM::::::M   M:::::::M   M::::::MC:::::C                  //
//      D:::::D     D:::::DE:::::E            C:::::C                L:::::L                    A:::::::::::::::::::::A     N::::::N    N::::::::::N  R::::R     R:::::RM::::::M    M:::::M    M::::::MC:::::C                  //
//      D:::::D    D:::::D E:::::E       EEEEEEC:::::C       CCCCCC  L:::::L         LLLLLL    A:::::AAAAAAAAAAAAA:::::A    N::::::N     N:::::::::N  R::::R     R:::::RM::::::M     MMMMM     M::::::M C:::::C       CCCCCC    //
//    DDD:::::DDDDD:::::DEE::::::EEEEEEEE:::::E C:::::CCCCCCCC::::CLL:::::::LLLLLLLLL:::::L   A:::::A             A:::::A   N::::::N      N::::::::NRR:::::R     R:::::RM::::::M               M::::::M  C:::::CCCCCCCC::::C    //
//    D:::::::::::::::DD E::::::::::::::::::::E  CC:::::::::::::::CL::::::::::::::::::::::L  A:::::A               A:::::A  N::::::N       N:::::::NR::::::R     R:::::RM::::::M               M::::::M   CC:::::::::::::::C    //
//    D::::::::::::DDD   E::::::::::::::::::::E    CCC::::::::::::CL::::::::::::::::::::::L A:::::A                 A:::::A N::::::N        N::::::NR::::::R     R:::::RM::::::M               M::::::M     CCC::::::::::::C    //
//    DDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEE       CCCCCCCCCCCCCLLLLLLLLLLLLLLLLLLLLLLLLAAAAAAA                   AAAAAAANNNNNNNN         NNNNNNNRRRRRRRR     RRRRRRRMMMMMMMM               MMMMMMMM        CCCCCCCCCCCCC    //
//                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DECLAN is ERC721Creator {
    constructor() ERC721Creator("DECLAN RMC", "DECLAN") {}
}