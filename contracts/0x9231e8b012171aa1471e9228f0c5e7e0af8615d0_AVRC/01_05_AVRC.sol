// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Avinro's contract
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//    In this contract, I'll be minting pieces that come out of my deepest being.    //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract AVRC is ERC721Creator {
    constructor() ERC721Creator("Avinro's contract", "AVRC") {}
}