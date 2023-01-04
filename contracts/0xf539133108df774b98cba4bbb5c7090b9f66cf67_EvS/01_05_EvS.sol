// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Evelyn O at SuperChief
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//    |_    _|   _   /  \   _  _  _|  (_     _  _ _ _|_ . _(_     //
//    |__\/(-|\/| )  \__/  (_|| )(_|  __)|_||_)(-| (_| )|(-|      //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract EvS is ERC721Creator {
    constructor() ERC721Creator("Evelyn O at SuperChief", "EvS") {}
}