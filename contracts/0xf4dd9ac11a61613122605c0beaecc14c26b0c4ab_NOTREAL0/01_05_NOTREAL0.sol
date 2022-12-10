// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: This isn't real [Open Edition]
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//      o      o           o                        //
//     <|>    <|>        _<|>_                      //
//     < >    / >                                   //
//      |     \o__ __o     o       __o__            //
//      o__/_  |     v\   <|>     />  \             //
//      |     / \     <\  / \     \o                //
//      |     \o/     o/  \o/      v\               //
//      o      |     <|    |        <\              //
//      <o__  / \    / \  / \  _\o_o// o            //
//     _<|>_                      /v  <|>           //
//                               />   < >           //
//       o       __o__ \o__ __o        |            //
//      <|>     />  \   |     |>       o__/_        //
//      / \     \o     / \   / \       |            //
//      \o/      v\    \o/   \o/       |            //
//       |        <\    |     |        o            //
//      / \  _\o__</   / \   / \       <\_o         //
//                                       <|>        //
//                                       / \        //
//     \o__ __o    o__  __o     o__ __o/ \o/        //
//      |     |>  /v      |>   /v     |   |         //
//     / \   < > />      //   />     / \ / \        //
//     \o/       \o    o/     \      \o/ \o/        //
//      |         v\  /v __o   o      |   |         //
//     / \         <\/> __/>   <\__  / \ / \        //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract NOTREAL0 is ERC1155Creator {
    constructor() ERC1155Creator("This isn't real [Open Edition]", "NOTREAL0") {}
}