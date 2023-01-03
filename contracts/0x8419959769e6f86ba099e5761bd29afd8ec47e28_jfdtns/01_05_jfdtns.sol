// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: josiah farrow editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//    𝚎𝚍𝚒𝚝𝚒𝚘𝚗𝚜 𝚋𝚢 𝚓𝚘𝚜𝚒𝚊𝚑 𝚏𝚊𝚛𝚛𝚘𝚠    //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract jfdtns is ERC1155Creator {
    constructor() ERC1155Creator("josiah farrow editions", "jfdtns") {}
}