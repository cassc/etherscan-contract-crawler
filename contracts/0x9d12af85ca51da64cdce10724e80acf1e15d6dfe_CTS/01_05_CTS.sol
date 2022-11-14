// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Creatures
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    /`|)[~ /|~|~| ||)[~(`      //
//    \,|\[_/-| | |_||\[__)      //
//                               //
//                               //
//                               //
///////////////////////////////////


contract CTS is ERC721Creator {
    constructor() ERC721Creator("Creatures", "CTS") {}
}