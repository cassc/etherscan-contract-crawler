// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFTbible by 1C4RU5
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//     ____  __  ____  __    ____     //
//    (  _ \(  )(  _ \(  )  (  __)    //
//     ) _ ( )(  ) _ (/ (_/\ ) _)     //
//    (____/(__)(____/\____/(____)    //
//                                    //
//                                    //
////////////////////////////////////////


contract BIBLE is ERC721Creator {
    constructor() ERC721Creator("NFTbible by 1C4RU5", "BIBLE") {}
}