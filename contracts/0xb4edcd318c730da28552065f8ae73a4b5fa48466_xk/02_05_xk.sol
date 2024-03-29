// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mare
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//                                                                //
//                                                                //
//       ________   ________   ________   ________                //
//      ╱        ╲ ╱        ╲ ╱        ╲ ╱        ╲               //
//     ╱         ╱╱         ╱╱         ╱╱         ╱               //
//    ╱         ╱╱         ╱╱        _╱╱        _╱                //
//    ╲__╱__╱__╱ ╲___╱____╱ ╲____╱___╱ ╲________╱                 //
//                                                                //
//                                                                //
//                                                                //
//                                                                //
//                                                                //
//                                                                //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract xk is ERC721Creator {
    constructor() ERC721Creator("mare", "xk") {}
}