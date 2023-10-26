// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PEPEHOUSE AIRDROP
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    PEPEHOUSE AIRDROP CONTRACT    //
//                                  //
//                                  //
//////////////////////////////////////


contract PHAD is ERC1155Creator {
    constructor() ERC1155Creator("PEPEHOUSE AIRDROP", "PHAD") {}
}