// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Boro's Mystical Adventure
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//    Join me on a quest to stop the evil wizard Santa    //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract Boro is ERC1155Creator {
    constructor() ERC1155Creator("Boro's Mystical Adventure", "Boro") {}
}