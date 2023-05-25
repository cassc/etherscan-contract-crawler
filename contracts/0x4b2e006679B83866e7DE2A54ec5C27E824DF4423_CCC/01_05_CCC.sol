// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CLUB CARD
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    Club Collective Club Card by Cod Mas    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract CCC is ERC1155Creator {
    constructor() ERC1155Creator("CLUB CARD", "CCC") {}
}