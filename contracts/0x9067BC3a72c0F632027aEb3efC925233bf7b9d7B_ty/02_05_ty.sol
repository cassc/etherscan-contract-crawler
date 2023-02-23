// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: tyslo
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//             tttt                                              lllllll                      //
//          ttt:::t                                              l:::::l                      //
//          t:::::t                                              l:::::l                      //
//          t:::::t                                              l:::::l                      //
//    ttttttt:::::tttttttyyyyyyy           yyyyyyy  ssssssssss    l::::l    ooooooooooo       //
//    t:::::::::::::::::t y:::::y         y:::::y ss::::::::::s   l::::l  oo:::::::::::oo     //
//    t:::::::::::::::::t  y:::::y       y:::::yss:::::::::::::s  l::::l o:::::::::::::::o    //
//    tttttt:::::::tttttt   y:::::y     y:::::y s::::::ssss:::::s l::::l o:::::ooooo:::::o    //
//          t:::::t          y:::::y   y:::::y   s:::::s  ssssss  l::::l o::::o     o::::o    //
//          t:::::t           y:::::y y:::::y      s::::::s       l::::l o::::o     o::::o    //
//          t:::::t            y:::::y:::::y          s::::::s    l::::l o::::o     o::::o    //
//          t:::::t    tttttt   y:::::::::y     ssssss   s:::::s  l::::l o::::o     o::::o    //
//          t::::::tttt:::::t    y:::::::y      s:::::ssss::::::sl::::::lo:::::ooooo:::::o    //
//          tt::::::::::::::t     y:::::y       s::::::::::::::s l::::::lo:::::::::::::::o    //
//            tt:::::::::::tt    y:::::y         s:::::::::::ss  l::::::l oo:::::::::::oo     //
//              ttttttttttt     y:::::y           sssssssssss    llllllll   ooooooooooo       //
//                             y:::::y                                                        //
//                            y:::::y                                                         //
//                           y:::::y                                                          //
//                          y:::::y                                                           //
//                         yyyyyyy                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract ty is ERC721Creator {
    constructor() ERC721Creator("tyslo", "ty") {}
}