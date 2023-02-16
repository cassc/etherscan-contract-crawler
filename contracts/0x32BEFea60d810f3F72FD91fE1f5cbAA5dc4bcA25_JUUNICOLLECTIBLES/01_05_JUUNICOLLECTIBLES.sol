// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JUUNI Collectibles
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////
//                                //
//                                //
//       _  _ _  _ _  _  _  _     //
//      | || | || | || \| || |    //
//      n_|||U || U || \\ || |    //
//     \__/|___||___||_|\_||_|    //
//                                //
//                                //
////////////////////////////////////


contract JUUNICOLLECTIBLES is ERC1155Creator {
    constructor() ERC1155Creator("JUUNI Collectibles", "JUUNICOLLECTIBLES") {}
}