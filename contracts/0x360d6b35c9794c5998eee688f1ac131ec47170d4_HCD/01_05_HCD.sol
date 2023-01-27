// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HappyChild
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    A child who does not know he is doing NFT    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract HCD is ERC1155Creator {
    constructor() ERC1155Creator("HappyChild", "HCD") {}
}