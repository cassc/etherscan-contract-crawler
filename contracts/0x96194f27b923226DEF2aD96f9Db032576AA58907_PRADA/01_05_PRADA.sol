// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PRADA X FUTURE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//    <<<------------ OWND TEST -------------->>>>>    //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract PRADA is ERC721Creator {
    constructor() ERC721Creator("PRADA X FUTURE", "PRADA") {}
}