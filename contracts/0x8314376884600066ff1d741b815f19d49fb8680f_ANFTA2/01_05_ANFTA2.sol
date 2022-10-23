// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aaron NFT Art Limited Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//        _   _  _ ___ _____ _   ___     //
//       /_\ | \| | __|_   _/_\ |_  )    //
//      / _ \| .` | _|  | |/ _ \ / /     //
//     /_/ \_|_|\_|_|   |_/_/ \_/___|    //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract ANFTA2 is ERC721Creator {
    constructor() ERC721Creator("Aaron NFT Art Limited Editions", "ANFTA2") {}
}