// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Savory Mints
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//                                                                            //
//                                  __   ___  __         ___ ___  __          //
//    |__| |  |  |\/|  /\  |\ |    / _` |__  /  \  |\/| |__   |  |__) \ /     //
//    |  | \__/  |  | /~~\ | \|    \__> |___ \__/  |  | |___  |  |  \  |      //
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract SAVORY is ERC1155Creator {
    constructor() ERC1155Creator("Savory Mints", "SAVORY") {}
}