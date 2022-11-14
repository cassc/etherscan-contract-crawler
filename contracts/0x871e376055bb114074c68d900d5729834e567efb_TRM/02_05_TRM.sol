// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Raw Motherhood 2.0
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    The Women Collective    //
//                            //
//                            //
////////////////////////////////


contract TRM is ERC721Creator {
    constructor() ERC721Creator("The Raw Motherhood 2.0", "TRM") {}
}