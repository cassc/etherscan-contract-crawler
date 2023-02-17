// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//    TTTTTTTTTTTTTTTTTTTTTTEEEEEEEEEEEEEEEEEEEEEE  SSSSSSSSSSSSSSSTTTTTTTTTTTTTTTTTTTTTTT    //
//    T:::::::::::::::::::::E::::::::::::::::::::ESS:::::::::::::::T:::::::::::::::::::::T    //
//    T:::::::::::::::::::::E::::::::::::::::::::S:::::SSSSSS::::::T:::::::::::::::::::::T    //
//    T:::::TT:::::::TT:::::EE::::::EEEEEEEEE::::S:::::S     SSSSSST:::::TT:::::::TT:::::T    //
//    TTTTTT  T:::::T  TTTTTT E:::::E       EEEEES:::::S           TTTTTT  T:::::T  TTTTTT    //
//            T:::::T         E:::::E            S:::::S                   T:::::T            //
//            T:::::T         E::::::EEEEEEEEEE   S::::SSSS                T:::::T            //
//            T:::::T         E:::::::::::::::E    SS::::::SSSSS           T:::::T            //
//            T:::::T         E:::::::::::::::E      SSS::::::::SS         T:::::T            //
//            T:::::T         E::::::EEEEEEEEEE         SSSSSS::::S        T:::::T            //
//            T:::::T         E:::::E                        S:::::S       T:::::T            //
//            T:::::T         E:::::E       EEEEEE           S:::::S       T:::::T            //
//          TT:::::::TT     EE::::::EEEEEEEE:::::SSSSSSS     S:::::S     TT:::::::TT          //
//          T:::::::::T     E::::::::::::::::::::S::::::SSSSSS:::::S     T:::::::::T          //
//          T:::::::::T     E::::::::::::::::::::S:::::::::::::::SS      T:::::::::T          //
//          TTTTTTTTTTT     EEEEEEEEEEEEEEEEEEEEEESSSSSSSSSSSSSSS        TTTTTTTTTTT          //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract DD is ERC1155Creator {
    constructor() ERC1155Creator("Test", "DD") {}
}