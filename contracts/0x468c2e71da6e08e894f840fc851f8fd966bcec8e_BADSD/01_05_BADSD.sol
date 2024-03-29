// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Admin Bad
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                               //
//                                                                                                               //
//       .-'''-.   ___    _  ______         ,-----.       .-'''-. .--.      .--.   ____    .-------.             //
//      / _     \.'   |  | ||    _ `''.   .'  .-,  '.    / _     \|  |_     |  | .'  __ `. \  _(`)_ \            //
//     (`' )/`--'|   .'  | || _ | ) _  \ / ,-.|  \ _ \  (`' )/`--'| _( )_   |  |/   '  \  \| (_ o._)|            //
//    (_ o _).   .'  '_  | ||( ''_'  ) |;  \  '_ /  | :(_ o _).   |(_ o _)  |  ||___|  /  ||  (_,_) /            //
//     (_,_). '. '   ( \.-.|| . (_) `. ||  _`,/ \ _/  | (_,_). '. | (_,_) \ |  |   _.-`   ||   '-.-'             //
//    .---.  \  :' (`. _` /||(_    ._) ': (  '\_/ \   ;.---.  \  :|  |/    \|  |.'   _    ||   |                 //
//    \    `-'  || (_ (_) _)|  (_.\.' /  \ `"/  \  ) / \    `-'  ||  '  /\  `  ||  _( )_  ||   |                 //
//     \       /  \ /  . \ /|       .'    '. \_/``".'   \       / |    /  \    |\ (_ o _) //   )                 //
//      `-...-'    ``-'`-'' '-----'`        '-----'      `-...-'  `---'    `---` '.(_,_).' `---'                 //
//       .-'''-.   ___    _     _______   .--.   .--.     .-'''-.                                                //
//      / _     \.'   |  | |   /   __  \  |  | _/  /     / _     \                                               //
//     (`' )/`--'|   .'  | |  | ,_/  \__) | (`' ) /     (`' )/`--'                                               //
//    (_ o _).   .'  '_  | |,-./  )       |(_ ()_)     (_ o _).                                                  //
//     (_,_). '. '   ( \.-.|\  '_ '`)     | (_,_)   __  (_,_). '.                                                //
//    .---.  \  :' (`. _` /| > (_)  )  __ |  |\ \  |  |.---.  \  :                                               //
//    \    `-'  || (_ (_) _)(  .  .-'_/  )|  | \ `'   /\    `-'  |                                               //
//     \       /  \ /  . \ / `-'`-'     / |  |  \    /  \       /                                                //
//      `-...-'    ``-'`-''    `._____.'  `--'   `'-'    `-...-'                                                 //
//                                                                                                               //
//                                                                                                               //
//                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BADSD is ERC721Creator {
    constructor() ERC721Creator("Admin Bad", "BADSD") {}
}