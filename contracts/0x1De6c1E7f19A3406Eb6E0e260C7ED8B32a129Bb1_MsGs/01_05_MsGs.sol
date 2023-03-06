// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moving Messages
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//     _______                                 _           //
//    |__   __|                       /\      | |          //
//       | | ___ _ __ _ __ _   _     /  \   __| |_   _     //
//       | |/ _ \ '__| '__| | | |   / /\ \ / _` | | | |    //
//       | |  __/ |  | |  | |_| |  / ____ \ (_| | |_| |    //
//       |_|\___|_|  |_|   \__, | /_/    \_\__,_|\__, |    //
//                          __/ |                 __/ |    //
//                         |___/                 |___/     //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract MsGs is ERC1155Creator {
    constructor() ERC1155Creator("Moving Messages", "MsGs") {}
}