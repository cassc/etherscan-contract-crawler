// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Abstract
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//                                                         //
//      ___  ____   __  ______ ____   ___    ___ ______    //
//     // \\ || )) (( \ | || | || \\ // \\  //   | || |    //
//     ||=|| ||=)   \\    ||   ||_// ||=|| ((      ||      //
//     || || ||_)) \_))   ||   || \\ || ||  \\__   ||      //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract ABSRT is ERC1155Creator {
    constructor() ERC1155Creator("Abstract", "ABSRT") {}
}