// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0BL8T10N
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    art offerings to the micro & macro masses    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract TORCH is ERC721Creator {
    constructor() ERC721Creator("0BL8T10N", "TORCH") {}
}