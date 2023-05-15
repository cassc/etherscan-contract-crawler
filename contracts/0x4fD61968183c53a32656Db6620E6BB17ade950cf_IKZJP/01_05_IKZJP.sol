// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Azuki Kyoto Garden Sponser Ticket
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    Azuki Kyoto IKZ    //
//                       //
//                       //
///////////////////////////


contract IKZJP is ERC1155Creator {
    constructor() ERC1155Creator("Azuki Kyoto Garden Sponser Ticket", "IKZJP") {}
}