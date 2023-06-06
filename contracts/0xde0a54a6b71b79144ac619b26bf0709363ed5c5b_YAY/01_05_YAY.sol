// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: INFINITEYAY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//     __    __  ______   __    __     //
//    /\ \  /\ \/\  _  \ /\ \  /\ \    //
//    \ `\`\\/'/\ \ \L\ \\ `\`\\/'/    //
//     `\ `\ /'  \ \  __ \`\ `\ /'     //
//       `\ \ \   \ \ \/\ \ `\ \ \     //
//         \ \_\   \ \_\ \_\  \ \_\    //
//          \/_/    \/_/\/_/   \/_/    //
//                                     //
//                                     //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract YAY is ERC721Creator {
    constructor() ERC721Creator("INFINITEYAY", "YAY") {}
}