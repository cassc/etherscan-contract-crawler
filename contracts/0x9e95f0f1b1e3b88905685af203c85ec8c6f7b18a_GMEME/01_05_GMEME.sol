// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GMEME
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//                                                                                                                                       //
//            GGGGGGGGGGGGGMMMMMMMM               MMMMMMMMEEEEEEEEEEEEEEEEEEEEEEMMMMMMMM               MMMMMMMMEEEEEEEEEEEEEEEEEEEEEE    //
//         GGG::::::::::::GM:::::::M             M:::::::ME::::::::::::::::::::EM:::::::M             M:::::::ME::::::::::::::::::::E    //
//       GG:::::::::::::::GM::::::::M           M::::::::ME::::::::::::::::::::EM::::::::M           M::::::::ME::::::::::::::::::::E    //
//      G:::::GGGGGGGG::::GM:::::::::M         M:::::::::MEE::::::EEEEEEEEE::::EM:::::::::M         M:::::::::MEE::::::EEEEEEEEE::::E    //
//     G:::::G       GGGGGGM::::::::::M       M::::::::::M  E:::::E       EEEEEEM::::::::::M       M::::::::::M  E:::::E       EEEEEE    //
//    G:::::G              M:::::::::::M     M:::::::::::M  E:::::E             M:::::::::::M     M:::::::::::M  E:::::E                 //
//    G:::::G              M:::::::M::::M   M::::M:::::::M  E::::::EEEEEEEEEE   M:::::::M::::M   M::::M:::::::M  E::::::EEEEEEEEEE       //
//    G:::::G    GGGGGGGGGGM::::::M M::::M M::::M M::::::M  E:::::::::::::::E   M::::::M M::::M M::::M M::::::M  E:::::::::::::::E       //
//    G:::::G    G::::::::GM::::::M  M::::M::::M  M::::::M  E:::::::::::::::E   M::::::M  M::::M::::M  M::::::M  E:::::::::::::::E       //
//    G:::::G    GGGGG::::GM::::::M   M:::::::M   M::::::M  E::::::EEEEEEEEEE   M::::::M   M:::::::M   M::::::M  E::::::EEEEEEEEEE       //
//    G:::::G        G::::GM::::::M    M:::::M    M::::::M  E:::::E             M::::::M    M:::::M    M::::::M  E:::::E                 //
//     G:::::G       G::::GM::::::M     MMMMM     M::::::M  E:::::E       EEEEEEM::::::M     MMMMM     M::::::M  E:::::E       EEEEEE    //
//      G:::::GGGGGGGG::::GM::::::M               M::::::MEE::::::EEEEEEEE:::::EM::::::M               M::::::MEE::::::EEEEEEEE:::::E    //
//       GG:::::::::::::::GM::::::M               M::::::ME::::::::::::::::::::EM::::::M               M::::::ME::::::::::::::::::::E    //
//         GGG::::::GGG:::GM::::::M               M::::::ME::::::::::::::::::::EM::::::M               M::::::ME::::::::::::::::::::E    //
//            GGGGGG   GGGGMMMMMMMM               MMMMMMMMEEEEEEEEEEEEEEEEEEEEEEMMMMMMMM               MMMMMMMMEEEEEEEEEEEEEEEEEEEEEE    //
//                                                                                                                                       //
//                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GMEME is ERC1155Creator {
    constructor() ERC1155Creator() {}
}