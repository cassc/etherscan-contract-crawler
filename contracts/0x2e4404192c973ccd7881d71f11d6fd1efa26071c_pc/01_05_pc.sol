// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepe Checks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//     ______                         ______ __               __               //
//    |   __ \.-----.-----.-----.    |      |  |--.-----.----|  |--.-----.     //
//    |    __/|  -__|  _  |  -__|    |   ---|     |  -__|  __|    <|__ --|     //
//    |___|   |_____|   __|_____|    |______|__|__|_____|____|__|__|_____|     //
//                  |__|                                                       //
//                                                                             //
//    Pepe Checks is pepengineered version of Visualize Value Checks.          //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


contract pc is ERC1155Creator {
    constructor() ERC1155Creator("Pepe Checks", "pc") {}
}