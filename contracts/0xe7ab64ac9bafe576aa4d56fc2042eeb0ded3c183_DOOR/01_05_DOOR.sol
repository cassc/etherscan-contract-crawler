// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Red Door
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                        dddddddd                                                                                    //
//    RRRRRRRRRRRRRRRRR                                   d::::::d     DDDDDDDDDDDDD                                                                  //
//    R::::::::::::::::R                                  d::::::d     D::::::::::::DDD                                                               //
//    R::::::RRRRRR:::::R                                 d::::::d     D:::::::::::::::DD                                                             //
//    RR:::::R     R:::::R                                d:::::d      DDD:::::DDDDD:::::D                                                            //
//      R::::R     R:::::R    eeeeeeeeeeee        ddddddddd:::::d        D:::::D    D:::::D    ooooooooooo      ooooooooooo   rrrrr   rrrrrrrrr       //
//      R::::R     R:::::R  ee::::::::::::ee    dd::::::::::::::d        D:::::D     D:::::D oo:::::::::::oo  oo:::::::::::oo r::::rrr:::::::::r      //
//      R::::RRRRRR:::::R  e::::::eeeee:::::ee d::::::::::::::::d        D:::::D     D:::::Do:::::::::::::::oo:::::::::::::::or:::::::::::::::::r     //
//      R:::::::::::::RR  e::::::e     e:::::ed:::::::ddddd:::::d        D:::::D     D:::::Do:::::ooooo:::::oo:::::ooooo:::::orr::::::rrrrr::::::r    //
//      R::::RRRRRR:::::R e:::::::eeeee::::::ed::::::d    d:::::d        D:::::D     D:::::Do::::o     o::::oo::::o     o::::o r:::::r     r:::::r    //
//      R::::R     R:::::Re:::::::::::::::::e d:::::d     d:::::d        D:::::D     D:::::Do::::o     o::::oo::::o     o::::o r:::::r     rrrrrrr    //
//      R::::R     R:::::Re::::::eeeeeeeeeee  d:::::d     d:::::d        D:::::D     D:::::Do::::o     o::::oo::::o     o::::o r:::::r                //
//      R::::R     R:::::Re:::::::e           d:::::d     d:::::d        D:::::D    D:::::D o::::o     o::::oo::::o     o::::o r:::::r                //
//    RR:::::R     R:::::Re::::::::e          d::::::ddddd::::::dd     DDD:::::DDDDD:::::D  o:::::ooooo:::::oo:::::ooooo:::::o r:::::r                //
//    R::::::R     R:::::R e::::::::eeeeeeee   d:::::::::::::::::d     D:::::::::::::::DD   o:::::::::::::::oo:::::::::::::::o r:::::r                //
//    R::::::R     R:::::R  ee:::::::::::::e    d:::::::::ddd::::d     D::::::::::::DDD      oo:::::::::::oo  oo:::::::::::oo  r:::::r                //
//    RRRRRRRR     RRRRRRR    eeeeeeeeeeeeee     ddddddddd   ddddd     DDDDDDDDDDDDD           ooooooooooo      ooooooooooo    rrrrrrr                //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
//                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DOOR is ERC1155Creator {
    constructor() ERC1155Creator("Red Door", "DOOR") {}
}