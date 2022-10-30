// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ETCH
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
//                                                                                                //
//                                                                                                //
//                                                                                                //
//    EEEEEEEEEEEEEEEEEEEEEETTTTTTTTTTTTTTTTTTTTTTT       CCCCCCCCCCCCCHHHHHHHHH     HHHHHHHHH    //
//    E::::::::::::::::::::ET:::::::::::::::::::::T    CCC::::::::::::CH:::::::H     H:::::::H    //
//    E::::::::::::::::::::ET:::::::::::::::::::::T  CC:::::::::::::::CH:::::::H     H:::::::H    //
//    EE::::::EEEEEEEEE::::ET:::::TT:::::::TT:::::T C:::::CCCCCCCC::::CHH::::::H     H::::::HH    //
//      E:::::E       EEEEEETTTTTT  T:::::T  TTTTTTC:::::C       CCCCCC  H:::::H     H:::::H      //
//      E:::::E                     T:::::T       C:::::C                H:::::H     H:::::H      //
//      E::::::EEEEEEEEEE           T:::::T       C:::::C                H::::::HHHHH::::::H      //
//      E:::::::::::::::E           T:::::T       C:::::C                H:::::::::::::::::H      //
//      E:::::::::::::::E           T:::::T       C:::::C                H:::::::::::::::::H      //
//      E::::::EEEEEEEEEE           T:::::T       C:::::C                H::::::HHHHH::::::H      //
//      E:::::E                     T:::::T       C:::::C                H:::::H     H:::::H      //
//      E:::::E       EEEEEE        T:::::T        C:::::C       CCCCCC  H:::::H     H:::::H      //
//    EE::::::EEEEEEEE:::::E      TT:::::::TT       C:::::CCCCCCCC::::CHH::::::H     H::::::HH    //
//    E::::::::::::::::::::E      T:::::::::T        CC:::::::::::::::CH:::::::H     H:::::::H    //
//    E::::::::::::::::::::E      T:::::::::T          CCC::::::::::::CH:::::::H     H:::::::H    //
//    EEEEEEEEEEEEEEEEEEEEEE      TTTTTTTTTTT             CCCCCCCCCCCCCHHHHHHHHH     HHHHHHHHH    //
//                                                                                                //
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////


contract ETCH is ERC721Creator {
    constructor() ERC721Creator("ETCH", "ETCH") {}
}