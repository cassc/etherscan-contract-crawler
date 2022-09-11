// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: doodles friends
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//    doodles friends are the colorful friends from the new world called prummies,a collection of 10000 friends,    //
//                                                                                                                  //
//    each doodles friends allows it owner to mint from pruummies,with unlockable content                           //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DOODLES is ERC721Creator {
    constructor() ERC721Creator("doodles friends", "DOODLES") {}
}