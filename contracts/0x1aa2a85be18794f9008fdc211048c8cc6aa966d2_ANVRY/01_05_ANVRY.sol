// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Watchers
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                      //
//                                                                                                                                                      //
//                                                                                                                                                      //
//               .-. .-')           ('-.         .-') _      .-') _              (`-.      ('-.  _  .-')    .-')     ('-.     _  .-')                   //
//               \  ( OO )         ( OO ).-.    ( OO ) )    ( OO ) )           _(OO  )_  _(  OO)( \( -O )  ( OO ).  ( OO ).-.( \( -O )                  //
//        .---.  ,--. ,--.         / . --. /,--./ ,--,' ,--./ ,--,' ,-.-') ,--(_/   ,. \(,------.,------. (_)---\_) / . --. / ,------.   ,--.   ,--.    //
//       / .  |  |  .'   /         | \-.  \ |   \ |  |\ |   \ |  |\ |  |OO)\   \   /(__/ |  .---'|   /`. '/    _ |  | \-.  \  |   /`. '   \  `.'  /     //
//      / /|  |  |      /,       .-'-'  |  ||    \|  | )|    \|  | )|  |  \ \   \ /   /  |  |    |  /  | |\  :` `..-'-'  |  | |  /  | | .-')     /      //
//     / / |  |_ |     ' _)       \| |_.'  ||  .     |/ |  .     |/ |  |(_/  \   '   /, (|  '--. |  |_.' | '..`''.)\| |_.'  | |  |_.' |(OO  \   /       //
//    /  '-'    ||  .   \          |  .-.  ||  |\    |  |  |\    | ,|  |_.'   \     /__) |  .--' |  .  '.'.-._)   \ |  .-.  | |  .  '.' |   /  /\_      //
//    `----|  |-'|  |\   \         |  | |  ||  | \   |  |  | \   |(_|  |       \   /     |  `---.|  |\  \ \       / |  | |  | |  |\  \  `-./  /.__)     //
//         `--'  `--' '--'         `--' `--'`--'  `--'  `--'  `--'  `--'        `-'      `------'`--' '--' `-----'  `--' `--' `--' '--'   `--'          //
//                                                                                                                                                      //
//                                                                                                                                                      //
//                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ANVRY is ERC721Creator {
    constructor() ERC721Creator("Watchers", "ANVRY") {}
}