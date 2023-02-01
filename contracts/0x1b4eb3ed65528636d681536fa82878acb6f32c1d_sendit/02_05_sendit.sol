// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SEND IT.OPEN
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                             .___.__  __          //
//      ______ ____   ____    __| _/|__|/  |_       //
//     /  ___// __ \ /    \  / __ | |  \   __\      //
//     \___ \\  ___/|   |  \/ /_/ | |  ||  |        //
//    /____  >\___  >___|  /\____ | |__||__| /\     //
//         \/     \/     \/      \/          \/     //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract sendit is ERC1155Creator {
    constructor() ERC1155Creator("SEND IT.OPEN", "sendit") {}
}