// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Ai Market
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//      ___  _  ___  ___           _        _       //
//     / _ \(_) |  \/  |          | |      | |      //
//    / /_\ \_  | .  . | __ _ _ __| | _____| |_     //
//    |  _  | | | |\/| |/ _` | '__| |/ / _ \ __|    //
//    | | | | | | |  | | (_| | |  |   <  __/ |_     //
//    \_| |_/_| \_|  |_/\__,_|_|  |_|\_\___|\__|    //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract ai is ERC1155Creator {
    constructor() ERC1155Creator("The Ai Market", "ai") {}
}