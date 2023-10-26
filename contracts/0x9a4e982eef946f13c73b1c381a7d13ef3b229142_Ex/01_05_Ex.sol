// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Existence
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                        //
//                                                                                                                                        //
//    From primal gasses to an abstract night sky scenery, this collection of 5 NFTs takes on Existince from an abstract perspective.     //
//                                                                                                                                        //
//                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Ex is ERC721Creator {
    constructor() ERC721Creator("Existence", "Ex") {}
}