// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wobblers OE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//                                                         //
//    .-.   .-.      .-.   .-.   .-.                       //
//    : :.-.: :      : :   : :   : :                       //
//    : :: :: : .--. : `-. : `-. : :   .--. .--.  .--.     //
//    : `' `' ;' .; :' .; :' .; :: :_ ' '_.': ..'`._-.'    //
//     `.,`.,' `.__.'`.__.'`.__.'`.__;`.__.':_;  `.__.'    //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract WOBBLE is ERC1155Creator {
    constructor() ERC1155Creator("Wobblers OE", "WOBBLE") {}
}