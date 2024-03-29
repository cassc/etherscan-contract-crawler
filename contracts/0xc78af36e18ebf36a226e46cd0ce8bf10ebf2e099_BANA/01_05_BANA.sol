// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Oshibana
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                   //
//                                                                                                   //
//        ,-----.       .-'''-. .---.  .---..-./`)  _______      ____    ,---.   .--.   ____         //
//      .'  .-,  '.    / _     \|   |  |_ _|\ .-.')\  ____  \  .'  __ `. |    \  |  | .'  __ `.      //
//     / ,-.|  \ _ \  (`' )/`--'|   |  ( ' )/ `-' \| |    \ | /   '  \  \|  ,  \ |  |/   '  \  \     //
//    ;  \  '_ /  | :(_ o _).   |   '-(_{;}_)`-'`"`| |____/ / |___|  /  ||  |\_ \|  ||___|  /  |     //
//    |  _`,/ \ _/  | (_,_). '. |      (_,_) .---. |   _ _ '.    _.-`   ||  _( )_\  |   _.-`   |     //
//    : (  '\_/ \   ;.---.  \  :| _ _--.   | |   | |  ( ' )  \.'   _    || (_ o _)  |.'   _    |     //
//     \ `"/  \  ) / \    `-'  ||( ' ) |   | |   | | (_{;}_) ||  _( )_  ||  (_,_)\  ||  _( )_  |     //
//      '. \_/``".'   \       / (_{;}_)|   | |   | |  (_,_)  /\ (_ o _) /|  |    |  |\ (_ o _) /     //
//        '-----'      `-...-'  '(_,_) '---' '---' /_______.'  '.(_,_).' '--'    '--' '.(_,_).'      //
//                                                                                                   //
//                                                                                                   //
//                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////


contract BANA is ERC721Creator {
    constructor() ERC721Creator("Oshibana", "BANA") {}
}