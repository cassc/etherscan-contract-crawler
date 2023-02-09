// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SB Checks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                                                                                         //
//    LLLLLLLLLLL             VVVVVVVV           VVVVVVVV     IIIIIIIIII     IIIIIIIIII    //
//    L:::::::::L             V::::::V           V::::::V     I::::::::I     I::::::::I    //
//    L:::::::::L             V::::::V           V::::::V     I::::::::I     I::::::::I    //
//    LL:::::::LL             V::::::V           V::::::V     II::::::II     II::::::II    //
//      L:::::L                V:::::V           V:::::V        I::::I         I::::I      //
//      L:::::L                 V:::::V         V:::::V         I::::I         I::::I      //
//      L:::::L                  V:::::V       V:::::V          I::::I         I::::I      //
//      L:::::L                   V:::::V     V:::::V           I::::I         I::::I      //
//      L:::::L                    V:::::V   V:::::V            I::::I         I::::I      //
//      L:::::L                     V:::::V V:::::V             I::::I         I::::I      //
//      L:::::L                      V:::::V:::::V              I::::I         I::::I      //
//      L:::::L         LLLLLL        V:::::::::V               I::::I         I::::I      //
//    LL:::::::LLLLLLLLL:::::L         V:::::::V              II::::::II     II::::::II    //
//    L::::::::::::::::::::::L          V:::::V               I::::::::I     I::::::::I    //
//    L::::::::::::::::::::::L           V:::V                I::::::::I     I::::::::I    //
//    LLLLLLLLLLLLLLLLLLLLLLLL            VVV                 IIIIIIIIII     IIIIIIIIII    //
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////


contract SBC is ERC1155Creator {
    constructor() ERC1155Creator("SB Checks", "SBC") {}
}