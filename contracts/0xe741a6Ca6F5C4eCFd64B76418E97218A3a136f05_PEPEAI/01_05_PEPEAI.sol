// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PepeAi by RoboticoAi
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//    PPPPPPPPPPPPPPPPP   EEEEEEEEEEEEEEEEEEEEEEPPPPPPPPPPPPPPPPP   EEEEEEEEEEEEEEEEEEEEEE               AAA               IIIIIIIIII    //
//    P::::::::::::::::P  E::::::::::::::::::::EP::::::::::::::::P  E::::::::::::::::::::E              A:::A              I::::::::I    //
//    P::::::PPPPPP:::::P E::::::::::::::::::::EP::::::PPPPPP:::::P E::::::::::::::::::::E             A:::::A             I::::::::I    //
//    PP:::::P     P:::::PEE::::::EEEEEEEEE::::EPP:::::P     P:::::PEE::::::EEEEEEEEE::::E            A:::::::A            II::::::II    //
//      P::::P     P:::::P  E:::::E       EEEEEE  P::::P     P:::::P  E:::::E       EEEEEE           A:::::::::A             I::::I      //
//      P::::P     P:::::P  E:::::E               P::::P     P:::::P  E:::::E                       A:::::A:::::A            I::::I      //
//      P::::PPPPPP:::::P   E::::::EEEEEEEEEE     P::::PPPPPP:::::P   E::::::EEEEEEEEEE            A:::::A A:::::A           I::::I      //
//      P:::::::::::::PP    E:::::::::::::::E     P:::::::::::::PP    E:::::::::::::::E           A:::::A   A:::::A          I::::I      //
//      P::::PPPPPPPPP      E:::::::::::::::E     P::::PPPPPPPPP      E:::::::::::::::E          A:::::A     A:::::A         I::::I      //
//      P::::P              E::::::EEEEEEEEEE     P::::P              E::::::EEEEEEEEEE         A:::::AAAAAAAAA:::::A        I::::I      //
//      P::::P              E:::::E               P::::P              E:::::E                  A:::::::::::::::::::::A       I::::I      //
//      P::::P              E:::::E       EEEEEE  P::::P              E:::::E       EEEEEE    A:::::AAAAAAAAAAAAA:::::A      I::::I      //
//    PP::::::PP          EE::::::EEEEEEEE:::::EPP::::::PP          EE::::::EEEEEEEE:::::E   A:::::A             A:::::A   II::::::II    //
//    P::::::::P          E::::::::::::::::::::EP::::::::P          E::::::::::::::::::::E  A:::::A               A:::::A  I::::::::I    //
//    P::::::::P          E::::::::::::::::::::EP::::::::P          E::::::::::::::::::::E A:::::A                 A:::::A I::::::::I    //
//    PPPPPPPPPP          EEEEEEEEEEEEEEEEEEEEEEPPPPPPPPPP          EEEEEEEEEEEEEEEEEEEEEEAAAAAAA                   AAAAAAAIIIIIIIIII    //
//                                                                                                                                       //
//                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PEPEAI is ERC721Creator {
    constructor() ERC721Creator("PepeAi by RoboticoAi", "PEPEAI") {}
}