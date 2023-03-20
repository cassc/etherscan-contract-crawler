// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Clowning Around
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//     ____   __  ____  __      //
//    (  _ \ /  \(__  )/  \     //
//     ) _ ((  O )/ _/(  O )    //
//    (____/ \__/(____)\__/     //
//                              //
//                              //
//////////////////////////////////


contract CA is ERC1155Creator {
    constructor() ERC1155Creator("Clowning Around", "CA") {}
}