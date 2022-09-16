// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cult Signet
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//                                 ,==.                 //
//                                 \\//                 //
//                                .-~~-.                //
//                              ,",-""-.".              //
//                             | |      | |             //
//                             | |   .-"| |.            //
//                             ". `,",-" ,'.".          //
//                               `| |_,-'   | |         //
//                                | |       | | CULT    //
//                                ". `-._,-' ."         //
//                                  `-.___,-'           //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract CSIG is ERC721Creator {
    constructor() ERC721Creator("Cult Signet", "CSIG") {}
}