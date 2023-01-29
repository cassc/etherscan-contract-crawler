// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ICHIKO Degital Bromaide
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//    IIIIIIIIII      CCCCCCCCCCCCCHHHHHHHHH     HHHHHHHHHIIIIIIIIIIKKKKKKKKK    KKKKKKK     OOOOOOOOO         //
//    I::::::::I   CCC::::::::::::CH:::::::H     H:::::::HI::::::::IK:::::::K    K:::::K   OO:::::::::OO       //
//    I::::::::I CC:::::::::::::::CH:::::::H     H:::::::HI::::::::IK:::::::K    K:::::K OO:::::::::::::OO     //
//    II::::::IIC:::::CCCCCCCC::::CHH::::::H     H::::::HHII::::::IIK:::::::K   K::::::KO:::::::OOO:::::::O    //
//      I::::I C:::::C       CCCCCC  H:::::H     H:::::H    I::::I  KK::::::K  K:::::KKKO::::::O   O::::::O    //
//      I::::IC:::::C                H:::::H     H:::::H    I::::I    K:::::K K:::::K   O:::::O     O:::::O    //
//      I::::IC:::::C                H::::::HHHHH::::::H    I::::I    K::::::K:::::K    O:::::O     O:::::O    //
//      I::::IC:::::C                H:::::::::::::::::H    I::::I    K:::::::::::K     O:::::O     O:::::O    //
//      I::::IC:::::C                H:::::::::::::::::H    I::::I    K:::::::::::K     O:::::O     O:::::O    //
//      I::::IC:::::C                H::::::HHHHH::::::H    I::::I    K::::::K:::::K    O:::::O     O:::::O    //
//      I::::IC:::::C                H:::::H     H:::::H    I::::I    K:::::K K:::::K   O:::::O     O:::::O    //
//      I::::I C:::::C       CCCCCC  H:::::H     H:::::H    I::::I  KK::::::K  K:::::KKKO::::::O   O::::::O    //
//    II::::::IIC:::::CCCCCCCC::::CHH::::::H     H::::::HHII::::::IIK:::::::K   K::::::KO:::::::OOO:::::::O    //
//    I::::::::I CC:::::::::::::::CH:::::::H     H:::::::HI::::::::IK:::::::K    K:::::K OO:::::::::::::OO     //
//    I::::::::I   CCC::::::::::::CH:::::::H     H:::::::HI::::::::IK:::::::K    K:::::K   OO:::::::::OO       //
//    IIIIIIIIII      CCCCCCCCCCCCCHHHHHHHHH     HHHHHHHHHIIIIIIIIIIKKKKKKKKK    KKKKKKK     OOOOOOOOO         //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract IDB is ERC1155Creator {
    constructor() ERC1155Creator("ICHIKO Degital Bromaide", "IDB") {}
}