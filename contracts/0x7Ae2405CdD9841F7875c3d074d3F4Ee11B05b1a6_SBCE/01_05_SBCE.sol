// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SuperBowl Checks: Eagles Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    SuperBowl Checks: Eagles Edition    //
//                                        //
//                                        //
////////////////////////////////////////////


contract SBCE is ERC1155Creator {
    constructor() ERC1155Creator("SuperBowl Checks: Eagles Edition", "SBCE") {}
}