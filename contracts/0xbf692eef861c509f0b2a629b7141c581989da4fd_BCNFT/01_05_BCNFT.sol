// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BlueChipNFTz
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    BlueChipNFTz.com    //
//                        //
//                        //
////////////////////////////


contract BCNFT is ERC721Creator {
    constructor() ERC721Creator("BlueChipNFTz", "BCNFT") {}
}