// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Collages by iuri kothe - 1of1s
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


contract ik is ERC721Creator {
    constructor() ERC721Creator("Collages by iuri kothe - 1of1s", "ik") {}
}