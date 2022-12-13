// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Transmissions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//             ______         __        //
//      ______/  __  \  _____/  |_      //
//     /  ___/>      < /    \   __\     //
//     \___ \/   --   \   |  \  |       //
//    /____  >______  /___|  /__|       //
//         \/       \/     \/           //
//                                      //
//                                      //
//////////////////////////////////////////


contract VOd is ERC1155Creator {
    constructor() ERC1155Creator("Transmissions", "VOd") {}
}