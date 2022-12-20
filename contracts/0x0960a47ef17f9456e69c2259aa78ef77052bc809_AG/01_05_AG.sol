// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Holy Shit Allah Gator
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    Art by Joan G. Stark                                            //
//                                                                    //
//                  _  _                                              //
//        _ _      (0)(0)-._  _.-'^^'^^'^^'^^'^^'--.                  //
//       (.(.)----'`        ^^'                /^   ^^-._             //
//       (    `                 \             |    _    ^^-._         //
//        VvvvvvvVv~~`__,/.._>  /:/:/:/:/:/:/:/\  (_..,______^^-.     //
//    jgs  `^^^^^^^^`/  /   /  /`^^^^^^^^^>^^>^`>  >        _`)  )    //
//                  (((`   (((`          (((`  (((`        `'--'^     //
//                                                                    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract AG is ERC1155Creator {
    constructor() ERC1155Creator("Holy Shit Allah Gator", "AG") {}
}