// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stairs by iuri kothe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    _________          _______ _________     //
//    \__   __/|\     /|(  ____ )\__   __/     //
//       ) (   | )   ( || (    )|   ) (        //
//       | |   | |   | || (____)|   | |        //
//       | |   | |   | ||     __)   | |        //
//       | |   | |   | || (\ (      | |        //
//    ___) (___| (___) || ) \ \_____) (___     //
//    \_______/(_______)|/   \__/\_______/     //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract STRS is ERC721Creator {
    constructor() ERC721Creator("Stairs by iuri kothe", "STRS") {}
}