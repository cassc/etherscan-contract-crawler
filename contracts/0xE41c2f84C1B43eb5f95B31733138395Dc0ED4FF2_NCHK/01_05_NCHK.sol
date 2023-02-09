// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NounsCheck10K
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    This is 'ReReMeme' Nouns + Check = NounsCheck     //
//                                                      //
//    No utility just art                               //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract NCHK is ERC721Creator {
    constructor() ERC721Creator("NounsCheck10K", "NCHK") {}
}