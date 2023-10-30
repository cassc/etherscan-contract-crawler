// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Maiskaya Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//    Fine art photographer | NFT artist | Traveler.     //
//     I don't take pictures, I create Art               //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract MAI is ERC1155Creator {
    constructor() ERC1155Creator("Maiskaya Editions", "MAI") {}
}