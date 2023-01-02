// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: noordinaryart
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//      o          o        o__ __o           o             //
//     <|\        <|>      /v     v\         <|>            //
//     / \\o      / \     />       <\        / \            //
//     \o/ v\     \o/   o/           \o    o/   \o          //
//      |   <\     |   <|             |>  <|__ __|>         //
//     / \    \o  / \   \\           //   /       \         //
//     \o/     v\ \o/     \         /   o/         \o       //
//      |       <\ |       o       o   /v           v\      //
//     / \        < \      <\__ __/>  />             <\     //
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract NOA is ERC721Creator {
    constructor() ERC721Creator("noordinaryart", "NOA") {}
}