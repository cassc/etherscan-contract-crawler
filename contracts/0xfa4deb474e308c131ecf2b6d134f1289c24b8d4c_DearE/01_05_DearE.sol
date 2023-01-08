// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dear Enemy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//                                                        //
//       ___|                                   |   |     //
//     \___ \    _` |  __ \    _` |  __ `__ \   |   |     //
//           |  (   |  |   |  (   |  |   |   |  ___ |     //
//     _____/  \__,_| _|  _| \__,_| _|  _|  _| _|  _|     //
//                                                        //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract DearE is ERC721Creator {
    constructor() ERC721Creator("Dear Enemy", "DearE") {}
}