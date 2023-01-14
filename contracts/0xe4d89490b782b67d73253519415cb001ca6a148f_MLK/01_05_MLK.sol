// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MLK
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    .___  ___.  __       __  ___     //
//    |   \/   | |  |     |  |/  /     //
//    |  \  /  | |  |     |  '  /      //
//    |  |\/|  | |  |     |    <       //
//    |  |  |  | |  `----.|  .  \      //
//    |__|  |__| |_______||__|\__\     //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract MLK is ERC1155Creator {
    constructor() ERC1155Creator("MLK", "MLK") {}
}