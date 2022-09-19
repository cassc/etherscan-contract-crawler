// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Meta Anubis
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                //
//                                                                                                                //
//    Meta Anubis collection consists of 10,000 unique and algorithmically-generated PFPs. All Meta Anubis are    //
//    special.                                                                                                    //
//                                                                                                                //
//                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MTA is ERC721Creator {
    constructor() ERC721Creator("Meta Anubis", "MTA") {}
}