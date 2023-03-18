// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mwk editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//      __  __  __          __  _  __       __      //
//     |  \/  | \ \        / / | |/ /    _  \ \     //
//     | \  / |  \ \  /\  / /  | ' /    (_)  | |    //
//     | |\/| |   \ \/  \/ /   |  <          | |    //
//     | |  | |    \  /\  /    | . \     _   | |    //
//     |_|  |_|     \/  \/     |_|\_\   (_)  | |    //
//                                          /_/     //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract mwk is ERC1155Creator {
    constructor() ERC1155Creator("mwk editions", "mwk") {}
}