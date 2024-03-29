// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: H01 Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//             _       _     _       _                       _          //
//            / /\    / /\ / /\     / /\                    /\ \        //
//           / / /   / / // /  \   / /  \                  /  \ \       //
//          / /_/   / / // / /\ \ /_/ /\ \                / /\ \ \      //
//         / /\ \__/ / // / /\ \ \\_\/\ \ \              / / /\ \_\     //
//        / /\ \___\/ //_/ /  \ \ \    \ \ \            / /_/_ \/_/     //
//       / / /\/___/ / \ \ \   \ \ \    \ \ \          / /____/\        //
//      / / /   / / /   \ \ \   \ \ \    \ \ \        / /\____\/        //
//     / / /   / / /     \ \ \___\ \ \  __\ \ \___   / / /______        //
//    / / /   / / /       \ \/____\ \ \/___\_\/__/\ / / /_______\       //
//    \/_/    \/_/         \_________\/\_________\/ \/__________/       //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract H01E is ERC1155Creator {
    constructor() ERC1155Creator("H01 Edition", "H01E") {}
}