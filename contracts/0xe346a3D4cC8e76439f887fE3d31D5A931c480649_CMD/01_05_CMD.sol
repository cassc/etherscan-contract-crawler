// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NCC Membership Coin
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
//    NNNNNNNN        NNNNNNNN        CCCCCCCCCCCCC       CCCCCCCCCCCCC    //
//    N:::::::N       N::::::N     CCC::::::::::::C    CCC::::::::::::C    //
//    N::::::::N      N::::::N   CC:::::::::::::::C  CC:::::::::::::::C    //
//    N:::::::::N     N::::::N  C:::::CCCCCCCC::::C C:::::CCCCCCCC::::C    //
//    N::::::::::N    N::::::N C:::::C       CCCCCCC:::::C       CCCCCC    //
//    N:::::::::::N   N::::::NC:::::C             C:::::C                  //
//    N:::::::N::::N  N::::::NC:::::C             C:::::C                  //
//    N::::::N N::::N N::::::NC:::::C             C:::::C                  //
//    N::::::N  N::::N:::::::NC:::::C             C:::::C                  //
//    N::::::N   N:::::::::::NC:::::C             C:::::C                  //
//    N::::::N    N::::::::::NC:::::C             C:::::C                  //
//    N::::::N     N:::::::::N C:::::C       CCCCCCC:::::C       CCCCCC    //
//    N::::::N      N::::::::N  C:::::CCCCCCCC::::C C:::::CCCCCCCC::::C    //
//    N::::::N       N:::::::N   CC:::::::::::::::C  CC:::::::::::::::C    //
//    N::::::N        N::::::N     CCC::::::::::::C    CCC::::::::::::C    //
//    NNNNNNNN         NNNNNNN        CCCCCCCCCCCCC       CCCCCCCCCCCCC    //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract CMD is ERC1155Creator {
    constructor() ERC1155Creator("NCC Membership Coin", "CMD") {}
}