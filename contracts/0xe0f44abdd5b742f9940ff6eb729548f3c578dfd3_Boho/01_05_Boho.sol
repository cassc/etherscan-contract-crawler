// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bounce
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//     __    __    _  _   __  _    ___  ___      //
//    |  \  /__\  | || | |  \| |  / _/ | __|     //
//    | -< | \/ | | \/ | | | ' | | \__ | _|      //
//    |__/  \__/   \__/  |_|\__|  \__/ |___|     //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract Boho is ERC721Creator {
    constructor() ERC721Creator("Bounce", "Boho") {}
}