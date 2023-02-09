// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: pixeljunkie OE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//           _          _ _             _    _          //
//          (_)        | (_)           | |  (_)         //
//     _ __  ___  _____| |_ _   _ _ __ | | ___  ___     //
//    | '_ \| \ \/ / _ \ | | | | | '_ \| |/ / |/ _ \    //
//    | |_) | |>  <  __/ | | |_| | | | |   <| |  __/    //
//    | .__/|_/_/\_\___|_| |\__,_|_| |_|_|\_\_|\___|    //
//    | |               _/ |                            //
//    |_|              |__/                             //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract pxl is ERC1155Creator {
    constructor() ERC1155Creator("pixeljunkie OE", "pxl") {}
}