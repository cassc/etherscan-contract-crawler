// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Liquid Variations
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//      _                                             //
//     |_) o  _. ._   _  _.   \  / o  _ _|_  _. |     //
//     |_) | (_| | | (_ (_|    \/  | (_  |_ (_| |     //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract LIQVA is ERC721Creator {
    constructor() ERC721Creator("Liquid Variations", "LIQVA") {}
}