// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Remarkable Women SIS 2023 Tribute NFT
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    Remarkable Women SIS 2023 Tribute NFT    //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract SiS is ERC1155Creator {
    constructor() ERC1155Creator("Remarkable Women SIS 2023 Tribute NFT", "SiS") {}
}