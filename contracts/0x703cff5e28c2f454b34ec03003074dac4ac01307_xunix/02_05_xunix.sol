// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Unix Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    _______                      .__            //
//    \   _  \ ___  _____ __  ____ |__|__  ___    //
//    /  /_\  \\  \/  /  |  \/    \|  \  \/  /    //
//    \  \_/   \>    <|  |  /   |  \  |>    <     //
//     \_____  /__/\_ \____/|___|  /__/__/\_ \    //
//           \/      \/          \/         \/    //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract xunix is ERC1155Creator {
    constructor() ERC1155Creator("Unix Editions", "xunix") {}
}