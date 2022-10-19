// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Satisfy® Norda™ 001
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//       __   _ ___ ___  __  ___        //
//      (_ ` /_) )   )  (_ ` )_ \_)     //
//     .__) / / (  _(_ .__) (    /      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract SYNAS is ERC721Creator {
    constructor() ERC721Creator(unicode"Satisfy® Norda™ 001", "SYNAS") {}
}