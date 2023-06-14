// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blooming Wonderland
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//     •✿✿ Blooming Wonderland ✿✿•    //
//                                    //
//                                    //
////////////////////////////////////////


contract BLOOM is ERC721Creator {
    constructor() ERC721Creator("Blooming Wonderland", "BLOOM") {}
}