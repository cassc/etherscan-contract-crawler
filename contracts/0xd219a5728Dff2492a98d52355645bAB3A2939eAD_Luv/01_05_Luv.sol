// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LoveChecks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    SHOW SOME LOVE TO SOMEBODY NO MATTER WHAT     //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract Luv is ERC1155Creator {
    constructor() ERC1155Creator("LoveChecks", "Luv") {}
}