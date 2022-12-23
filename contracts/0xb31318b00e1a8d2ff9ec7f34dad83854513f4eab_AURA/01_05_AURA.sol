// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ascended 1st Open Edition Drop
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//             o                                                              o                        o      //
//            <|>                                                            <|>                      <|>     //
//            / \                                                            < \                      < \     //
//          o/   \o           __o__    __o__    o__  __o   \o__ __o     o__ __o/    o__  __o     o__ __o/     //
//         <|__ __|>         />  \    />  \    /v      |>   |     |>   /v     |    /v      |>   /v     |      //
//         /       \         \o     o/        />      //   / \   / \  />     / \  />      //   />     / \     //
//       o/         \o        v\   <|         \o    o/     \o/   \o/  \      \o/  \o    o/     \      \o/     //
//      /v           v\        <\   \\         v\  /v __o   |     |    o      |    v\  /v __o   o      |      //
//     />             <\  _\o__</    _\o__</    <\/> __/>  / \   / \   <\__  / \    <\/> __/>   <\__  / \     //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AURA is ERC721Creator {
    constructor() ERC721Creator("Ascended 1st Open Edition Drop", "AURA") {}
}