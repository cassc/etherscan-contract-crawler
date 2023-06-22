// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LOVE DRaiGONS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    LOVE DRaiGONS  _)               (_        //
//                  _) \ /\_/\ /\_/\ / (_       //
//                 _)  \\(0 0) (0 0)//  (_      //
//    NFTs by      )_ -- \(oo) (oo)/ -- _(      //
//    Sarcastic     )_ / /\\__,__//\ \ _(       //
//    Songs          )_ /   --;--   \ _(        //
//               *.    ( (  )) ((  ) )    .*    //
//                 '...(____)x x(____)...'      //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract LDGN is ERC721Creator {
    constructor() ERC721Creator("LOVE DRaiGONS", "LDGN") {}
}