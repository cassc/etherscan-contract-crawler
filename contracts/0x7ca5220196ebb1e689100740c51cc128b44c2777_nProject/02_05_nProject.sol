// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The n project #002
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                  //
//                                                                                                                                  //
//    This is the first cryptofolk chilean EP: It represents the promise of the youngest cultural patrimoniumin chilean history.    //
//    The n project #002 is a cryptofolk extended play of chilean cueca.                                                            //
//    Create your reality: n is you, n is me & everyone.                                                                            //
//                                                                                                                                  //
//                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract nProject is ERC1155Creator {
    constructor() ERC1155Creator("The n project #002", "nProject") {}
}