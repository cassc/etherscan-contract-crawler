// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tomislav
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//     _____               _     _                 //
//    |_   _|__  _ __ ___ (_)___| | __ ___   __    //
//      | |/ _ \| '_ ` _ \| / __| |/ _` \ \ / /    //
//      | | (_) | | | | | | \__ \ | (_| |\ V /     //
//      |_|\___/|_| |_| |_|_|___/_|\__,_| \_/      //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract TOM is ERC1155Creator {
    constructor() ERC1155Creator("Tomislav", "TOM") {}
}