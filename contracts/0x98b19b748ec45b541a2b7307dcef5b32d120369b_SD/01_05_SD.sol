// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: STABILITY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                      //
//                                                                                                                                                      //
//                                                                                                                                                      //
//                                                                                                                                                      //
//                                                           bbbbbbbb                                                                                   //
//       SSSSSSSSSSSSSSS      tttt                           b::::::b              iiii  lllllll   iiii          tttt                                   //
//     SS:::::::::::::::S  ttt:::t                           b::::::b             i::::i l:::::l  i::::i      ttt:::t                                   //
//    S:::::SSSSSS::::::S  t:::::t                           b::::::b              iiii  l:::::l   iiii       t:::::t                                   //
//    S:::::S     SSSSSSS  t:::::t                            b:::::b                    l:::::l              t:::::t                                   //
//    S:::::S        ttttttt:::::ttttttt      aaaaaaaaaaaaa   b:::::bbbbbbbbb    iiiiiii  l::::l iiiiiiittttttt:::::tttttttyyyyyyy           yyyyyyy    //
//    S:::::S        t:::::::::::::::::t      a::::::::::::a  b::::::::::::::bb  i:::::i  l::::l i:::::it:::::::::::::::::t y:::::y         y:::::y     //
//     S::::SSSS     t:::::::::::::::::t      aaaaaaaaa:::::a b::::::::::::::::b  i::::i  l::::l  i::::it:::::::::::::::::t  y:::::y       y:::::y      //
//      SS::::::SSSSStttttt:::::::tttttt               a::::a b:::::bbbbb:::::::b i::::i  l::::l  i::::itttttt:::::::tttttt   y:::::y     y:::::y       //
//        SSS::::::::SS    t:::::t              aaaaaaa:::::a b:::::b    b::::::b i::::i  l::::l  i::::i      t:::::t          y:::::y   y:::::y        //
//           SSSSSS::::S   t:::::t            aa::::::::::::a b:::::b     b:::::b i::::i  l::::l  i::::i      t:::::t           y:::::y y:::::y         //
//                S:::::S  t:::::t           a::::aaaa::::::a b:::::b     b:::::b i::::i  l::::l  i::::i      t:::::t            y:::::y:::::y          //
//                S:::::S  t:::::t    tttttta::::a    a:::::a b:::::b     b:::::b i::::i  l::::l  i::::i      t:::::t    tttttt   y:::::::::y           //
//    SSSSSSS     S:::::S  t::::::tttt:::::ta::::a    a:::::a b:::::bbbbbb::::::bi::::::il::::::li::::::i     t::::::tttt:::::t    y:::::::y            //
//    S::::::SSSSSS:::::S  tt::::::::::::::ta:::::aaaa::::::a b::::::::::::::::b i::::::il::::::li::::::i     tt::::::::::::::t     y:::::y             //
//    S:::::::::::::::SS     tt:::::::::::tt a::::::::::aa:::ab:::::::::::::::b  i::::::il::::::li::::::i       tt:::::::::::tt    y:::::y              //
//     SSSSSSSSSSSSSSS         ttttttttttt    aaaaaaaaaa  aaaabbbbbbbbbbbbbbbb   iiiiiiiilllllllliiiiiiii         ttttttttttt     y:::::y               //
//                                                                                                                               y:::::y                //
//                                                                                                                              y:::::y                 //
//                                                                                                                                                      //
//                                                                                                                                                      //
//                                                                                                                                                      //
//                                                                                                                                                      //
//                                                                                                                                                      //
//                                                                                                                                                      //
//                                                                                                                                                      //
//                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SD is ERC721Creator {
    constructor() ERC721Creator("STABILITY", "SD") {}
}