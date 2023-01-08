// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ghosts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
//                       /)                                //
//                   _  (/   ___ _  _/_ _                  //
//                  (_/_/ )_(_) /_)_(__/_)_                //
//                 .-/                                     //
//                (_/                                      //
//                                                         //
//                                                         //
//                                                         //
//      the only collection by Jubbish for portraiture     //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract JTG is ERC721Creator {
    constructor() ERC721Creator("ghosts", "JTG") {}
}