// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions by iuri kothe
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

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


contract ik is ERC1155Creator {
    constructor() ERC1155Creator("Editions by iuri kothe", "ik") {}
}