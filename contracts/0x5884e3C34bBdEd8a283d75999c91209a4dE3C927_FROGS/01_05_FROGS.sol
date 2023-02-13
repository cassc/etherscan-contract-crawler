// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Frogs
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                       //
//                                                                                                                                                       //
//    Frogs, with their symphonic croaks echoing through the night, remind us of the beauty of stillness and the power of still waters that run deep.    //
//                                                                                                                                                       //
//                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FROGS is ERC1155Creator {
    constructor() ERC1155Creator("Frogs", "FROGS") {}
}