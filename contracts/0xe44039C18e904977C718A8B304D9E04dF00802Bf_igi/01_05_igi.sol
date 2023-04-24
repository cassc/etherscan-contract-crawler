// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Igi (editions)
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//                                                                                    //
//                                                                                    //
//                                                                                    //
//                                                                                    //
//                                                                                    //
//      iiii                                                                iiii      //
//     i::::i                                                              i::::i     //
//      iiii                                                                iiii      //
//                                                                                    //
//    iiiiiii    ggggggggg   ggggg   ggggggggg   ggggg   ggggggggg   gggggiiiiiii     //
//    i:::::i   g:::::::::ggg::::g  g:::::::::ggg::::g  g:::::::::ggg::::gi:::::i     //
//     i::::i  g:::::::::::::::::g g:::::::::::::::::g g:::::::::::::::::g i::::i     //
//     i::::i g::::::ggggg::::::ggg::::::ggggg::::::ggg::::::ggggg::::::gg i::::i     //
//     i::::i g:::::g     g:::::g g:::::g     g:::::g g:::::g     g:::::g  i::::i     //
//     i::::i g:::::g     g:::::g g:::::g     g:::::g g:::::g     g:::::g  i::::i     //
//     i::::i g:::::g     g:::::g g:::::g     g:::::g g:::::g     g:::::g  i::::i     //
//     i::::i g::::::g    g:::::g g::::::g    g:::::g g::::::g    g:::::g  i::::i     //
//    i::::::ig:::::::ggggg:::::g g:::::::ggggg:::::g g:::::::ggggg:::::g i::::::i    //
//    i::::::i g::::::::::::::::g  g::::::::::::::::g  g::::::::::::::::g i::::::i    //
//    i::::::i  gg::::::::::::::g   gg::::::::::::::g   gg::::::::::::::g i::::::i    //
//    iiiiiiii    gggggggg::::::g     gggggggg::::::g     gggggggg::::::g iiiiiiii    //
//                        g:::::g             g:::::g             g:::::g             //
//            gggggg      g:::::g gggggg      g:::::g gggggg      g:::::g             //
//            g:::::gg   gg:::::g g:::::gg   gg:::::g g:::::gg   gg:::::g             //
//             g::::::ggg:::::::g  g::::::ggg:::::::g  g::::::ggg:::::::g             //
//              gg:::::::::::::g    gg:::::::::::::g    gg:::::::::::::g              //
//                ggg::::::ggg        ggg::::::ggg        ggg::::::ggg                //
//                   gggggg              gggggg              gggggg                   //
//                                                                                    //
//                                                                                    //
//                                                                                    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////


contract igi is ERC1155Creator {
    constructor() ERC1155Creator("Igi (editions)", "igi") {}
}