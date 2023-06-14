// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chapitre Trois
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//                                                                        //
//           _                                                            //
//          | |               o                                o          //
//      __  | |     __,    _    _|_  ,_    _    _|_  ,_    __      ,      //
//     /    |/ \   /  |  |/ \_|  |  /  |  |/     |  /  |  /  \_|  / \_    //
//     \___/|   |_/\_/|_/|__/ |_/|_/   |_/|__/   |_/   |_/\__/ |_/ \/o    //
//                      /|                                                //
//                      \|                                                //
//                                                                        //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract VNX is ERC1155Creator {
    constructor() ERC1155Creator("Chapitre Trois", "VNX") {}
}