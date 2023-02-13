// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Soundscapes by Hulki Okan Tabak
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//      _,  _, _,_ _, _ __,  _,  _,  _, __, __,  _,    //
//     (_  / \ | | |\ | | \ (_  / ` /_\ |_) |_  (_     //
//     , ) \ / | | | \| |_/ , ) \ , | | |   |   , )    //
//      ~   ~  `~' ~  ~ ~    ~   ~  ~ ~ ~   ~~~  ~     //
//                                                     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract SNDHOT is ERC721Creator {
    constructor() ERC721Creator("Soundscapes by Hulki Okan Tabak", "SNDHOT") {}
}