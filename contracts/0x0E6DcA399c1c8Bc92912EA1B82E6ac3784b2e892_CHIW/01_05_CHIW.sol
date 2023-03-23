// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CH's inner world
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//       ______                                                        //
//     .~      ~. |         | | `.               .'                    //
//    |           |_________| |   `.           .'                      //
//    |           |         | |     `.   .   .'                        //
//     `.______.' |         | |       `.' `.'                          //
//                                                  CH. March, 2023    //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract CHIW is ERC721Creator {
    constructor() ERC721Creator("CH's inner world", "CHIW") {}
}