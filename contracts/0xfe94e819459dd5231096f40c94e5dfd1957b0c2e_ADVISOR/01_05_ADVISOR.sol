// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Potus and his Advisor.
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    Here to entartain...MEMES!    //
//                                  //
//                                  //
//////////////////////////////////////


contract ADVISOR is ERC1155Creator {
    constructor() ERC1155Creator("Potus and his Advisor.", "ADVISOR") {}
}