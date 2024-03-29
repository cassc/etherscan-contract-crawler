// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Synoptic's Foundation
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//      ____                           _ _      _               //
//     |___ \_   _  __ _  ___   __ _ _| (_)___ ( )___           //
//     / ___| | | |/ _` |/ _ \ / _` |__ | |__ \ \|__ \          //
//    | (___| |_| | | | | (_) | (_| |_| | |__) | / __/          //
//     \____| .__/|_| |_|\___/ \__, |__/|_|___/  \___|          //
//           \___|                |_|                           //
//     _____                   _            _ _                 //
//    |___  | ___  _   _  __ _| |__  _ __ _| (_) ___   __ _     //
//       _| |/ _ \| | | |/ _` | '_ \| '_ |__ | |/ _ \ / _` |    //
//      |_  | (_) | |_| | | | | |_) | |_) _| | | (_) | | | |    //
//        |_|\___/|_.__/|_| |_|_.__/|_.__|__/|_|\___/|_| |_|    //
//                                                              //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract SYN is ERC1155Creator {
    constructor() ERC1155Creator() {}
}