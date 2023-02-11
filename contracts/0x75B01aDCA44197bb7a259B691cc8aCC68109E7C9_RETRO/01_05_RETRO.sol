// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RETRO LIFE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
//    RRRRRRRRRRRRRRRRR   EEEEEEEEEEEEEEEEEEEEEETTTTTTTTTTTTTTTTTTTTTTTRRRRRRRRRRRRRRRRR        OOOOOOOOO          LLLLLLLLLLL             IIIIIIIIIIFFFFFFFFFFFFFFFFFFFFFFEEEEEEEEEEEEEEEEEEEEEE    //
//    R::::::::::::::::R  E::::::::::::::::::::ET:::::::::::::::::::::TR::::::::::::::::R     OO:::::::::OO        L:::::::::L             I::::::::IF::::::::::::::::::::FE::::::::::::::::::::E    //
//    R::::::RRRRRR:::::R E::::::::::::::::::::ET:::::::::::::::::::::TR::::::RRRRRR:::::R  OO:::::::::::::OO      L:::::::::L             I::::::::IF::::::::::::::::::::FE::::::::::::::::::::E    //
//    RR:::::R     R:::::REE::::::EEEEEEEEE::::ET:::::TT:::::::TT:::::TRR:::::R     R:::::RO:::::::OOO:::::::O     LL:::::::LL             II::::::IIFF::::::FFFFFFFFF::::FEE::::::EEEEEEEEE::::E    //
//      R::::R     R:::::R  E:::::E       EEEEEETTTTTT  T:::::T  TTTTTT  R::::R     R:::::RO::::::O   O::::::O       L:::::L                 I::::I    F:::::F       FFFFFF  E:::::E       EEEEEE    //
//      R::::R     R:::::R  E:::::E                     T:::::T          R::::R     R:::::RO:::::O     O:::::O       L:::::L                 I::::I    F:::::F               E:::::E                 //
//      R::::RRRRRR:::::R   E::::::EEEEEEEEEE           T:::::T          R::::RRRRRR:::::R O:::::O     O:::::O       L:::::L                 I::::I    F::::::FFFFFFFFFF     E::::::EEEEEEEEEE       //
//      R:::::::::::::RR    E:::::::::::::::E           T:::::T          R:::::::::::::RR  O:::::O     O:::::O       L:::::L                 I::::I    F:::::::::::::::F     E:::::::::::::::E       //
//      R::::RRRRRR:::::R   E:::::::::::::::E           T:::::T          R::::RRRRRR:::::R O:::::O     O:::::O       L:::::L                 I::::I    F:::::::::::::::F     E:::::::::::::::E       //
//      R::::R     R:::::R  E::::::EEEEEEEEEE           T:::::T          R::::R     R:::::RO:::::O     O:::::O       L:::::L                 I::::I    F::::::FFFFFFFFFF     E::::::EEEEEEEEEE       //
//      R::::R     R:::::R  E:::::E                     T:::::T          R::::R     R:::::RO:::::O     O:::::O       L:::::L                 I::::I    F:::::F               E:::::E                 //
//      R::::R     R:::::R  E:::::E       EEEEEE        T:::::T          R::::R     R:::::RO::::::O   O::::::O       L:::::L         LLLLLL  I::::I    F:::::F               E:::::E       EEEEEE    //
//    RR:::::R     R:::::REE::::::EEEEEEEE:::::E      TT:::::::TT      RR:::::R     R:::::RO:::::::OOO:::::::O     LL:::::::LLLLLLLLL:::::LII::::::IIFF:::::::FF           EE::::::EEEEEEEE:::::E    //
//    R::::::R     R:::::RE::::::::::::::::::::E      T:::::::::T      R::::::R     R:::::R OO:::::::::::::OO      L::::::::::::::::::::::LI::::::::IF::::::::FF           E::::::::::::::::::::E    //
//    R::::::R     R:::::RE::::::::::::::::::::E      T:::::::::T      R::::::R     R:::::R   OO:::::::::OO        L::::::::::::::::::::::LI::::::::IF::::::::FF           E::::::::::::::::::::E    //
//    RRRRRRRR     RRRRRRREEEEEEEEEEEEEEEEEEEEEE      TTTTTTTTTTT      RRRRRRRR     RRRRRRR     OOOOOOOOO          LLLLLLLLLLLLLLLLLLLLLLLLIIIIIIIIIIFFFFFFFFFFF           EEEEEEEEEEEEEEEEEEEEEE    //
//                                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
//                                                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RETRO is ERC721Creator {
    constructor() ERC721Creator("RETRO LIFE", "RETRO") {}
}