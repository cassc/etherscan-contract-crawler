// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fringe Koans
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//           .__                                        //
//      _____|__|______  ______ ____ _____    ____      //
//     /  ___/  \_  __ \/  ___// __ \\__  \  /    \     //
//     \___ \|  ||  | \/\___ \\  ___/ / __ \|   |  \    //
//    /____  >__||__|  /____  >\___  >____  /___|  /    //
//         \/               \/     \/     \/     \/     //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract FKOAN is ERC1155Creator {
    constructor() ERC1155Creator("Fringe Koans", "FKOAN") {}
}