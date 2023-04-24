// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The 4/20 Gas Wars
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                7???7JYY .??7?J                                                                             //
//               ~BBBBBBBB!J#BBBB!.                                                                           //
//             !5BBBBBBBB#GGGBBBB#7                                                                           //
//          .!PBBBBB#&&&#~BB5&&&&!PG                                                                          //
//          ~GBBBBBBB#@@#.^JBG&@@:^^   -- .- -.- . / .--. . .--. . / --. .-. . .- - / .- --. .- .. -.         //
//          ~PBBBBBBBBBBBBBBBBBBBBB5                                                                          //
//          ~PBBBB57!!!!!!!!!!!!!!!^                                                                          //
//           ^BBBBG?~~~~~~~~~~~~~!!^                                                                          //
//            ~5BBBBBBBBBBBBBBBBBGY~                                                                          //
//             :^~BBBBBBBBBBBB7^~^                                                                            //
//           .G7?GBBBBGGBGBBBBB5~G^                                                                           //
//           .B.^#BBBBGGPGBBBB#? G~                                                                           //
//           .B.^#BBBBBBBBBBBBB? G~                                                                           //
//            Y ^#BBBBBBBBBBBBBJ J:                                                                           //
//              ^#BBBBBBBBBBBBBJ                                                                              //
//              ^#BBBBB5YBBBBBBJ                                                                              //
//              ^#BBBB#^ BBBBBBJ                                                 PEPOLONIA: CRIBBIT GANG!     //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CGGW is ERC1155Creator {
    constructor() ERC1155Creator("The 4/20 Gas Wars", "CGGW") {}
}