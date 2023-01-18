// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Token of Gratitude - AirDrop
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
//    MMMMMMMM               MMMMMMMM                                            //
//    M:::::::M             M:::::::M                                            //
//    M::::::::M           M::::::::M                                            //
//    M:::::::::M         M:::::::::M                                            //
//    M::::::::::M       M::::::::::M  aaaaaaaaaaaaayyyyyyy           yyyyyyy    //
//    M:::::::::::M     M:::::::::::M  a::::::::::::ay:::::y         y:::::y     //
//    M:::::::M::::M   M::::M:::::::M  aaaaaaaaa:::::ay:::::y       y:::::y      //
//    M::::::M M::::M M::::M M::::::M           a::::a y:::::y     y:::::y       //
//    M::::::M  M::::M::::M  M::::::M    aaaaaaa:::::a  y:::::y   y:::::y        //
//    M::::::M   M:::::::M   M::::::M  aa::::::::::::a   y:::::y y:::::y         //
//    M::::::M    M:::::M    M::::::M a::::aaaa::::::a    y:::::y:::::y          //
//    M::::::M     MMMMM     M::::::Ma::::a    a:::::a     y:::::::::y           //
//    M::::::M               M::::::Ma::::a    a:::::a      y:::::::y            //
//    M::::::M               M::::::Ma:::::aaaa::::::a       y:::::y             //
//    M::::::M               M::::::M a::::::::::aa:::a     y:::::y              //
//    MMMMMMMM               MMMMMMMM  aaaaaaaaaa  aaaa    y:::::y               //
//                                                        y:::::y                //
//                                                       y:::::y                 //
//                                                      y:::::y                  //
//                                                     y:::::y                   //
//                                                    yyyyyyy                    //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////


contract TGA is ERC1155Creator {
    constructor() ERC1155Creator("Token of Gratitude - AirDrop", "TGA") {}
}