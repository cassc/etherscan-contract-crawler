// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: quaternion
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    81 85 65    //
//                //
//                //
////////////////////


contract QUA is ERC721Creator {
    constructor() ERC721Creator("quaternion", "QUA") {}
}