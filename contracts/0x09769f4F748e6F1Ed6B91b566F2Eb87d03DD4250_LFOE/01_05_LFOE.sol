// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Laurence Fuller Open Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//       __ .---.                         //
//                __ /  `  .-.7,--.       //
//               /  `. .-''. -,  , \      //
//               '--.-    -;   | ) /      //
//               ,` /   \ ,_) /   '-.     //
//              /  (  (  |   /  .' ) \    //
//              '.  `--,/   .---' ,-.|    //
//                `--.  / '-, -' .'       //
//               .==,=; `-,.;--'          //
//              / ,'  _;--;|              //
//             /_...='    ||              //
//                    LF  || .==,=.       //
//                        ||/    '.\      //
//                       ,||`'=...__\     //
//                        ||              //
//                        ||              //
//                        ||,             //
//                        ||              //
//                        ||              //
//                        ||              //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract LFOE is ERC1155Creator {
    constructor() ERC1155Creator("Laurence Fuller Open Editions", "LFOE") {}
}