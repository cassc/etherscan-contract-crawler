// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GM
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//                                                            //
//            GGGGGGGGGGGGGMMMMMMMM               MMMMMMMM    //
//         GGG::::::::::::GM:::::::M             M:::::::M    //
//       GG:::::::::::::::GM::::::::M           M::::::::M    //
//      G:::::GGGGGGGG::::GM:::::::::M         M:::::::::M    //
//     G:::::G       GGGGGGM::::::::::M       M::::::::::M    //
//    G:::::G              M:::::::::::M     M:::::::::::M    //
//    G:::::G              M:::::::M::::M   M::::M:::::::M    //
//    G:::::G    GGGGGGGGGGM::::::M M::::M M::::M M::::::M    //
//    G:::::G    G::::::::GM::::::M  M::::M::::M  M::::::M    //
//    G:::::G    GGGGG::::GM::::::M   M:::::::M   M::::::M    //
//    G:::::G        G::::GM::::::M    M:::::M    M::::::M    //
//     G:::::G       G::::GM::::::M     MMMMM     M::::::M    //
//      G:::::GGGGGGGG::::GM::::::M               M::::::M    //
//       GG:::::::::::::::GM::::::M               M::::::M    //
//         GGG::::::GGG:::GM::::::M               M::::::M    //
//            GGGGGG   GGGGMMMMMMMM               MMMMMMMM    //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract GM is ERC1155Creator {
    constructor() ERC1155Creator("GM", "GM") {}
}