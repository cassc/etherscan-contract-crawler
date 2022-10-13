// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mynewtoken
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////
//           //
//           //
//    non    //
//           //
//           //
///////////////


contract token is ERC721Creator {
    constructor() ERC721Creator("mynewtoken", "token") {}
}