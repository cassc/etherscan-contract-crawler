// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Before You Exist Everywhere
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                     ,▄                                                 //
//                            └       ▓█     a▓▀                                          //
//                               └╙▓▓▀█▀▀▀╠▓╙╙▌╙╙╙╙╙▀╙               ,                    //
//                ,,     ,µª▀█   ▄▀  ]▀ ╓▀   ╟¬        ,▄»≈*▀▌    ╓Θ╠█  ╓═╗Æ▀▄            //
//             ╙└└ ▐▌,,▄▀   ▐▌ Æ▀   ,█Æ▀    ]▌  ▄K"]█ ╠b    ▐⌐ ▄K╙  █▄"  ▓▄Æ█▌    ,▄Æ▀    //
//                 ▐▌,╩     ╙▀`      `      █Æ▀    ╙▀"└     ╙▀└          └   └└           //
//                 ╘▀`                                                                    //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract OE is ERC1155Creator {
    constructor() ERC1155Creator("Before You Exist Everywhere", "OE") {}
}