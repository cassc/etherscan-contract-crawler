// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IROIRO Holder Drops
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//    ᐠ(  ᐢ ᵕ ᐢ )ᐟ    //
//                    //
//                    //
////////////////////////


contract IROIRO is ERC1155Creator {
    constructor() ERC1155Creator("IROIRO Holder Drops", "IROIRO") {}
}