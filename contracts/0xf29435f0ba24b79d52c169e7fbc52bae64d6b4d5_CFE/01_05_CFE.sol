// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CEXALINE FREEMINT EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//    FFFFFFFFFFFFFFFFFFFFFFRRRRRRRRRRRRRRRRR   EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE    //
//    F::::::::::::::::::::FR::::::::::::::::R  E::::::::::::::::::::EE::::::::::::::::::::E    //
//    F::::::::::::::::::::FR::::::RRRRRR:::::R E::::::::::::::::::::EE::::::::::::::::::::E    //
//    FF::::::FFFFFFFFF::::FRR:::::R     R:::::REE::::::EEEEEEEEE::::EEE::::::EEEEEEEEE::::E    //
//      F:::::F       FFFFFF  R::::R     R:::::R  E:::::E       EEEEEE  E:::::E       EEEEEE    //
//      F:::::F               R::::R     R:::::R  E:::::E               E:::::E                 //
//      F::::::FFFFFFFFFF     R::::RRRRRR:::::R   E::::::EEEEEEEEEE     E::::::EEEEEEEEEE       //
//      F:::::::::::::::F     R:::::::::::::RR    E:::::::::::::::E     E:::::::::::::::E       //
//      F:::::::::::::::F     R::::RRRRRR:::::R   E:::::::::::::::E     E:::::::::::::::E       //
//      F::::::FFFFFFFFFF     R::::R     R:::::R  E::::::EEEEEEEEEE     E::::::EEEEEEEEEE       //
//      F:::::F               R::::R     R:::::R  E:::::E               E:::::E                 //
//      F:::::F               R::::R     R:::::R  E:::::E       EEEEEE  E:::::E       EEEEEE    //
//    FF:::::::FF           RR:::::R     R:::::REE::::::EEEEEEEE:::::EEE::::::EEEEEEEE:::::E    //
//    F::::::::FF           R::::::R     R:::::RE::::::::::::::::::::EE::::::::::::::::::::E    //
//    F::::::::FF           R::::::R     R:::::RE::::::::::::::::::::EE::::::::::::::::::::E    //
//    FFFFFFFFFFF           RRRRRRRR     RRRRRRREEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE    //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////


contract CFE is ERC1155Creator {
    constructor() ERC1155Creator("CEXALINE FREEMINT EDITIONS", "CFE") {}
}