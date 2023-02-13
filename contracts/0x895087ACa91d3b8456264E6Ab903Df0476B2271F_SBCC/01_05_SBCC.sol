// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SuperBowl Checks: Chiefs Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    SuperBowl Checks: Chiefs Edition    //
//                                        //
//                                        //
////////////////////////////////////////////


contract SBCC is ERC1155Creator {
    constructor() ERC1155Creator("SuperBowl Checks: Chiefs Edition", "SBCC") {}
}