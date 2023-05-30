// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Forge
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//    ___       ___     ___  __   __   __   ___     //
//     |  |__| |__     |__  /  \ |__) / _` |__      //
//     |  |  | |___    |    \__/ |  \ \__> |___     //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract FORGE is ERC1155Creator {
    constructor() ERC1155Creator("The Forge", "FORGE") {}
}