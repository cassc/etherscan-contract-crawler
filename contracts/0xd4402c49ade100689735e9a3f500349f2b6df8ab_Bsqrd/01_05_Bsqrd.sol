// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BooBoos
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    Mindfully Following Spirit    //
//                                  //
//                                  //
//////////////////////////////////////


contract Bsqrd is ERC721Creator {
    constructor() ERC721Creator("BooBoos", "Bsqrd") {}
}