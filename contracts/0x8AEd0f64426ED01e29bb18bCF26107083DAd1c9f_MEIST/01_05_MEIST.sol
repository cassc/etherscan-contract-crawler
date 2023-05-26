// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Smolmei Stamps
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                   _           _     //
//      ____ __  ___| |_ __  ___(_)    //
//     (_-< '  \/ _ \ | '  \/ -_) |    //
//     /__/_|_|_\___/_|_|_|_\___|_|    //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract MEIST is ERC1155Creator {
    constructor() ERC1155Creator("Smolmei Stamps", "MEIST") {}
}