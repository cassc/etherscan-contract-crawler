// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Christmass Airdrop
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    s0meone_u_know    //
//                      //
//                      //
//////////////////////////


contract Chirstmass is ERC1155Creator {
    constructor() ERC1155Creator("Christmass Airdrop", "Chirstmass") {}
}