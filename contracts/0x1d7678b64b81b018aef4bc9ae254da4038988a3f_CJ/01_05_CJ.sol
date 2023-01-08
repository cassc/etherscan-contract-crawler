// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Colorful jewel
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    🅲🅾🅻🅾🆁🅵🆄🅻 🅹🅴🆆🅴🅻    //
//                                   //
//                                   //
///////////////////////////////////////


contract CJ is ERC721Creator {
    constructor() ERC721Creator("Colorful jewel", "CJ") {}
}