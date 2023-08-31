// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IMF
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//    sttttttttttttttttteeeeeeeeeeeeeeeeeeeeeeevvvvvvvvvvvvveeeeeeeeeeeeee    //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract IMF is ERC1155Creator {
    constructor() ERC1155Creator("IMF", "IMF") {}
}