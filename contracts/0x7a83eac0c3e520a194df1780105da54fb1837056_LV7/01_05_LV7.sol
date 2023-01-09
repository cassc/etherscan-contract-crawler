// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: islava
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//                                      //
//             (                        //
//     (       )\    )   )       )      //
//     )\  (  ((_)( /(  /((   ( /(      //
//    ((_) )\  _  )(_))(_))\  )(_))     //
//     (_)((_)| |((_)_ _)((_)((_)_      //
//     | |(_-<| |/ _` |\ V / / _` |     //
//     |_|/__/|_|\__,_| \_/  \__,_|     //
//                                      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract LV7 is ERC721Creator {
    constructor() ERC721Creator("islava", "LV7") {}
}