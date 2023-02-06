// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Too Turnt for Taxes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    ________________  ____  ___           //
//    \__    ___/  _  \ \   \/  /           //
//      |    | /  /_\  \ \     /            //
//      |    |/    |    \/     \            //
//      |____|\____|__  /___/\  \           //
//                    \/      \_/           //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract Tax is ERC1155Creator {
    constructor() ERC1155Creator("Too Turnt for Taxes", "Tax") {}
}