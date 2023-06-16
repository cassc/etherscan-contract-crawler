// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BNXY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    1/1 BNXY Collection by Akashi30.    //
//                                        //
//    Commercial right for holders.       //
//                                        //
//                                        //
////////////////////////////////////////////


contract BNXY is ERC721Creator {
    constructor() ERC721Creator("BNXY", "BNXY") {}
}