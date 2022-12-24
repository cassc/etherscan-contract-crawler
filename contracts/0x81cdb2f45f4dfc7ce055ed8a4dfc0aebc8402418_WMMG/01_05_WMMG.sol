// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Where My Memes Go
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//    WWWWWWWW                           WWWWWWWWMMMMMMMM               MMMMMMMMMMMMMMMM               MMMMMMMM        GGGGGGGGGGGGG    //
//    W::::::W                           W::::::WM:::::::M             M:::::::MM:::::::M             M:::::::M     GGG::::::::::::G    //
//    W::::::W                           W::::::WM::::::::M           M::::::::MM::::::::M           M::::::::M   GG:::::::::::::::G    //
//    W::::::W                           W::::::WM:::::::::M         M:::::::::MM:::::::::M         M:::::::::M  G:::::GGGGGGGG::::G    //
//     W:::::W           WWWWW           W:::::W M::::::::::M       M::::::::::MM::::::::::M       M::::::::::M G:::::G       GGGGGG    //
//      W:::::W         W:::::W         W:::::W  M:::::::::::M     M:::::::::::MM:::::::::::M     M:::::::::::MG:::::G                  //
//       W:::::W       W:::::::W       W:::::W   M:::::::M::::M   M::::M:::::::MM:::::::M::::M   M::::M:::::::MG:::::G                  //
//        W:::::W     W:::::::::W     W:::::W    M::::::M M::::M M::::M M::::::MM::::::M M::::M M::::M M::::::MG:::::G    GGGGGGGGGG    //
//         W:::::W   W:::::W:::::W   W:::::W     M::::::M  M::::M::::M  M::::::MM::::::M  M::::M::::M  M::::::MG:::::G    G::::::::G    //
//          W:::::W W:::::W W:::::W W:::::W      M::::::M   M:::::::M   M::::::MM::::::M   M:::::::M   M::::::MG:::::G    GGGGG::::G    //
//           W:::::W:::::W   W:::::W:::::W       M::::::M    M:::::M    M::::::MM::::::M    M:::::M    M::::::MG:::::G        G::::G    //
//            W:::::::::W     W:::::::::W        M::::::M     MMMMM     M::::::MM::::::M     MMMMM     M::::::M G:::::G       G::::G    //
//             W:::::::W       W:::::::W         M::::::M               M::::::MM::::::M               M::::::M  G:::::GGGGGGGG::::G    //
//              W:::::W         W:::::W          M::::::M               M::::::MM::::::M               M::::::M   GG:::::::::::::::G    //
//               W:::W           W:::W           M::::::M               M::::::MM::::::M               M::::::M     GGG::::::GGG:::G    //
//                WWW             WWW            MMMMMMMM               MMMMMMMMMMMMMMMM               MMMMMMMM        GGGGGG   GGGG    //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WMMG is ERC1155Creator {
    constructor() ERC1155Creator("Where My Memes Go", "WMMG") {}
}