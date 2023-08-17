// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Heavy FOMA
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//       __ __                     ________  __  ______     //
//      / // /__ ___ __  ____ __  / __/ __ \/  |/  / _ |    //
//     / _  / -_) _ `/ |/ / // / / _// /_/ / /|_/ / __ |    //
//    /_//_/\__/\_,_/|___/\_, / /_/  \____/_/  /_/_/ |_|    //
//                       /___/                              //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract HFOMA is ERC1155Creator {
    constructor() ERC1155Creator("Heavy FOMA", "HFOMA") {}
}