// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Doobrex
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                            //
//                                                                                                                                            //
//                                                          bbbbbbbb                                                                          //
//    DDDDDDDDDDDDD                                         b::::::b                                                                          //
//    D::::::::::::DDD                                      b::::::b                                                                          //
//    D:::::::::::::::DD                                    b::::::b                                                                          //
//    DDD:::::DDDDD:::::D                                    b:::::b                                                                          //
//      D:::::D    D:::::D    ooooooooooo      ooooooooooo   b:::::bbbbbbbbb    rrrrr   rrrrrrrrr       eeeeeeeeeeee  xxxxxxx      xxxxxxx    //
//      D:::::D     D:::::D oo:::::::::::oo  oo:::::::::::oo b::::::::::::::bb  r::::rrr:::::::::r    ee::::::::::::ee x:::::x    x:::::x     //
//      D:::::D     D:::::Do:::::::::::::::oo:::::::::::::::ob::::::::::::::::b r:::::::::::::::::r  e::::::eeeee:::::eex:::::x  x:::::x      //
//      D:::::D     D:::::Do:::::ooooo:::::oo:::::ooooo:::::ob:::::bbbbb:::::::brr::::::rrrrr::::::re::::::e     e:::::e x:::::xx:::::x       //
//      D:::::D     D:::::Do::::o     o::::oo::::o     o::::ob:::::b    b::::::b r:::::r     r:::::re:::::::eeeee::::::e  x::::::::::x        //
//      D:::::D     D:::::Do::::o     o::::oo::::o     o::::ob:::::b     b:::::b r:::::r     rrrrrrre:::::::::::::::::e    x::::::::x         //
//      D:::::D     D:::::Do::::o     o::::oo::::o     o::::ob:::::b     b:::::b r:::::r            e::::::eeeeeeeeeee     x::::::::x         //
//      D:::::D    D:::::D o::::o     o::::oo::::o     o::::ob:::::b     b:::::b r:::::r            e:::::::e             x::::::::::x        //
//    DDD:::::DDDDD:::::D  o:::::ooooo:::::oo:::::ooooo:::::ob:::::bbbbbb::::::b r:::::r            e::::::::e           x:::::xx:::::x       //
//    D:::::::::::::::DD   o:::::::::::::::oo:::::::::::::::ob::::::::::::::::b  r:::::r             e::::::::eeeeeeee  x:::::x  x:::::x      //
//    D::::::::::::DDD      oo:::::::::::oo  oo:::::::::::oo b:::::::::::::::b   r:::::r              ee:::::::::::::e x:::::x    x:::::x     //
//    DDDDDDDDDDDDD           ooooooooooo      ooooooooooo   bbbbbbbbbbbbbbbb    rrrrrrr                eeeeeeeeeeeeeexxxxxxx      xxxxxxx    //
//                                                                                                                                            //
//                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Dbx is ERC1155Creator {
    constructor() ERC1155Creator() {}
}