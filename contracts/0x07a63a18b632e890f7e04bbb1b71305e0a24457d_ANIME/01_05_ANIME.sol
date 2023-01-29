// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anime Shore Event Collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//       ____   __  _  _  __  __  ____        //
//      / () \ |  \| || ||  \/  || ===|       //
//     /__/\__\|_|\__||_||_|\/|_||____|       //
//                                            //
//                                            //
////////////////////////////////////////////////


contract ANIME is ERC721Creator {
    constructor() ERC721Creator("Anime Shore Event Collection", "ANIME") {}
}