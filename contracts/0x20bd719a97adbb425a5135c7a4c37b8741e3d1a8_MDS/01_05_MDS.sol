// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tinita_ttin
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//      _____ _      _ _            //
//     |_   _(_)_ _ (_) |_ __ _     //
//       | | | | ' \| |  _/ _` |    //
//       |_| |_|_||_|_|\__\__,_|    //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract MDS is ERC1155Creator {
    constructor() ERC1155Creator("Tinita_ttin", "MDS") {}
}