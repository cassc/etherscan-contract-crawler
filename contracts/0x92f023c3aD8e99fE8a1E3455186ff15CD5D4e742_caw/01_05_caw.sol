// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: code+wood
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                       //
//                                                                                                                                                                                                       //
//                                                                                                                                                                                                       //
//                                                     dddddddd                                                                                                                              dddddddd    //
//                                                     d::::::d                                                                                                                              d::::::d    //
//                                                     d::::::d                                                                                                                              d::::::d    //
//                                                     d::::::d                                                                                                                              d::::::d    //
//                                                     d:::::d                            +++++++                                                                                            d:::::d     //
//        cccccccccccccccc   ooooooooooo       ddddddddd:::::d     eeeeeeeeeeee           +:::::+       wwwwwww           wwwww           wwwwwww ooooooooooo      ooooooooooo       ddddddddd:::::d     //
//      cc:::::::::::::::c oo:::::::::::oo   dd::::::::::::::d   ee::::::::::::ee         +:::::+        w:::::w         w:::::w         w:::::woo:::::::::::oo  oo:::::::::::oo   dd::::::::::::::d     //
//     c:::::::::::::::::co:::::::::::::::o d::::::::::::::::d  e::::::eeeee:::::ee +++++++:::::+++++++   w:::::w       w:::::::w       w:::::wo:::::::::::::::oo:::::::::::::::o d::::::::::::::::d     //
//    c:::::::cccccc:::::co:::::ooooo:::::od:::::::ddddd:::::d e::::::e     e:::::e +:::::::::::::::::+    w:::::w     w:::::::::w     w:::::w o:::::ooooo:::::oo:::::ooooo:::::od:::::::ddddd:::::d     //
//    c::::::c     ccccccco::::o     o::::od::::::d    d:::::d e:::::::eeeee::::::e +:::::::::::::::::+     w:::::w   w:::::w:::::w   w:::::w  o::::o     o::::oo::::o     o::::od::::::d    d:::::d     //
//    c:::::c             o::::o     o::::od:::::d     d:::::d e:::::::::::::::::e  +++++++:::::+++++++      w:::::w w:::::w w:::::w w:::::w   o::::o     o::::oo::::o     o::::od:::::d     d:::::d     //
//    c:::::c             o::::o     o::::od:::::d     d:::::d e::::::eeeeeeeeeee         +:::::+             w:::::w:::::w   w:::::w:::::w    o::::o     o::::oo::::o     o::::od:::::d     d:::::d     //
//    c::::::c     ccccccco::::o     o::::od:::::d     d:::::d e:::::::e                  +:::::+              w:::::::::w     w:::::::::w     o::::o     o::::oo::::o     o::::od:::::d     d:::::d     //
//    c:::::::cccccc:::::co:::::ooooo:::::od::::::ddddd::::::dde::::::::e                 +++++++               w:::::::w       w:::::::w      o:::::ooooo:::::oo:::::ooooo:::::od::::::ddddd::::::dd    //
//     c:::::::::::::::::co:::::::::::::::o d:::::::::::::::::d e::::::::eeeeeeee                                w:::::w         w:::::w       o:::::::::::::::oo:::::::::::::::o d:::::::::::::::::d    //
//      cc:::::::::::::::c oo:::::::::::oo   d:::::::::ddd::::d  ee:::::::::::::e                                 w:::w           w:::w         oo:::::::::::oo  oo:::::::::::oo   d:::::::::ddd::::d    //
//        cccccccccccccccc   ooooooooooo      ddddddddd   ddddd    eeeeeeeeeeeeee                                  www             www            ooooooooooo      ooooooooooo      ddddddddd   ddddd    //
//                                                                                                                                                                                                       //
//                                                                                                                                                                                                       //
//                                                                                                                                                                                                       //
//                                                                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract caw is ERC721Creator {
    constructor() ERC721Creator("code+wood", "caw") {}
}