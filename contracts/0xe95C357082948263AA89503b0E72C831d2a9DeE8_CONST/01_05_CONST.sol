// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Constant
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//            CCCCCCCCCCCCC     OOOOOOOOO     NNNNNNNN        NNNNNNNNTTTTTTTTTTTTTTTTTTTTTTT   SSSSSSSSSSSSSSS     //
//         CCC::::::::::::C   OO:::::::::OO   N:::::::N       N::::::NT:::::::::::::::::::::T SS:::::::::::::::S    //
//       CC:::::::::::::::C OO:::::::::::::OO N::::::::N      N::::::NT:::::::::::::::::::::TS:::::SSSSSS::::::S    //
//      C:::::CCCCCCCC::::CO:::::::OOO:::::::ON:::::::::N     N::::::NT:::::TT:::::::TT:::::TS:::::S     SSSSSSS    //
//     C:::::C       CCCCCCO::::::O   O::::::ON::::::::::N    N::::::NTTTTTT  T:::::T  TTTTTTS:::::S                //
//    C:::::C              O:::::O     O:::::ON:::::::::::N   N::::::N        T:::::T        S:::::S                //
//    C:::::C              O:::::O     O:::::ON:::::::N::::N  N::::::N        T:::::T         S::::SSSS             //
//    C:::::C              O:::::O     O:::::ON::::::N N::::N N::::::N        T:::::T          SS::::::SSSSS        //
//    C:::::C              O:::::O     O:::::ON::::::N  N::::N:::::::N        T:::::T            SSS::::::::SS      //
//    C:::::C              O:::::O     O:::::ON::::::N   N:::::::::::N        T:::::T               SSSSSS::::S     //
//    C:::::C              O:::::O     O:::::ON::::::N    N::::::::::N        T:::::T                    S:::::S    //
//     C:::::C       CCCCCCO::::::O   O::::::ON::::::N     N:::::::::N        T:::::T                    S:::::S    //
//      C:::::CCCCCCCC::::CO:::::::OOO:::::::ON::::::N      N::::::::N      TT:::::::TT      SSSSSSS     S:::::S    //
//       CC:::::::::::::::C OO:::::::::::::OO N::::::N       N:::::::N      T:::::::::T      S::::::SSSSSS:::::S    //
//         CCC::::::::::::C   OO:::::::::OO   N::::::N        N::::::N      T:::::::::T      S:::::::::::::::SS     //
//            CCCCCCCCCCCCC     OOOOOOOOO     NNNNNNNN         NNNNNNN      TTTTTTTTTTT       SSSSSSSSSSSSSSS       //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CONST is ERC1155Creator {
    constructor() ERC1155Creator("Constant", "CONST") {}
}