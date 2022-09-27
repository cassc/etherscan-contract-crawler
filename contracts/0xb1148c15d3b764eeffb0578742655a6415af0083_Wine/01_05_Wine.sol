// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Enjoy Wine by Winomy
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Enjoy Wine by Winomy    //
//                            //
//                            //
////////////////////////////////


contract Wine is ERC721Creator {
    constructor() ERC721Creator("Enjoy Wine by Winomy", "Wine") {}
}