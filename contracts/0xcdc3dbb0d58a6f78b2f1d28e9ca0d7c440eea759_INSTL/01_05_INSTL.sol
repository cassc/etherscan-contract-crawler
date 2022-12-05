// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: installation alpha by  ̶r̶e̶d̶a̶c̶t̶e̶d̶
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                                                                         //
//    ██████  ███████ ██████   █████   ██████ ████████ ███████ ██████      //
//    ██   ██ ██      ██   ██ ██   ██ ██         ██    ██      ██   ██     //
//    ██████  █████   ██   ██ ███████ ██         ██    █████   ██   ██     //
//    ██   ██ ██      ██   ██ ██   ██ ██         ██    ██      ██   ██     //
//    ██   ██ ███████ ██████  ██   ██  ██████    ██    ███████ ██████      //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract INSTL is ERC721Creator {
    constructor() ERC721Creator(unicode"installation alpha by  ̶r̶e̶d̶a̶c̶t̶e̶d̶", "INSTL") {}
}