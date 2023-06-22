// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Peachy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    Everything is better with you.             //
//    Everything has been better since you. ♡    //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract ILY is ERC721Creator {
    constructor() ERC721Creator("Peachy", "ILY") {}
}