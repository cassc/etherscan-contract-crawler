// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Seasonal festivals in megaranica!
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//       .-'''-.     .-''-.     ____       .-'''-.     ,-----.    ,---.   .--.   ____      .---.                                        //
//      / _     \  .'_ _   \  .'  __ `.   / _     \  .'  .-,  '.  |    \  |  | .'  __ `.   | ,_|                                        //
//     (`' )/`--' / ( ` )   '/   '  \  \ (`' )/`--' / ,-.|  \ _ \ |  ,  \ |  |/   '  \  \,-./  )                                        //
//    (_ o _).   . (_ o _)  ||___|  /  |(_ o _).   ;  \  '_ /  | :|  |\_ \|  ||___|  /  |\  '_ '`)                                      //
//     (_,_). '. |  (_,_)___|   _.-`   | (_,_). '. |  _`,/ \ _/  ||  _( )_\  |   _.-`   | > (_)  )                                      //
//    .---.  \  :'  \   .---..'   _    |.---.  \  :: (  '\_/ \   ;| (_ o _)  |.'   _    |(  .  .-'                                      //
//    \    `-'  | \  `-'    /|  _( )_  |\    `-'  | \ `"/  \  ) / |  (_,_)\  ||  _( )_  | `-'`-'|___                                    //
//     \       /   \       / \ (_ o _) / \       /   '. \_/``".'  |  |    |  |\ (_ o _) /  |        \                                   //
//      `-...-'     `'-..-'   '.(_,_).'   `-...-'      '-----'    '--'    '--' '.(_,_).'   `--------`                                   //
//     ________     .-''-.     .-'''-. ,---------. .-./`) ,---.  ,---.   ____      .---.       .-'''-.                                  //
//    |        |  .'_ _   \   / _     \\          \\ .-.')|   /  |   | .'  __ `.   | ,_|      / _     \                                 //
//    |   .----' / ( ` )   ' (`' )/`--' `--.  ,---'/ `-' \|  |   |  .'/   '  \  \,-./  )     (`' )/`--'                                 //
//    |  _|____ . (_ o _)  |(_ o _).       |   \    `-'`"`|  | _ |  | |___|  /  |\  '_ '`)  (_ o _).                                    //
//    |_( )_   ||  (_,_)___| (_,_). '.     :_ _:    .---. |  _( )_  |    _.-`   | > (_)  )   (_,_). '.                                  //
//    (_ o._)__|'  \   .---..---.  \  :    (_I_)    |   | \ (_ o._) / .'   _    |(  .  .-'  .---.  \  :                                 //
//    |(_,_)     \  `-'    /\    `-'  |   (_(=)_)   |   |  \ (_,_) /  |  _( )_  | `-'`-'|___\    `-'  |                                 //
//    |   |       \       /  \       /     (_I_)    |   |   \     /   \ (_ o _) /  |        \\       /                                  //
//    '---'        `'-..-'    `-...-'      '---'    '---'    `---`     '.(_,_).'   `--------` `-...-'                                   //
//    .-./`) ,---.   .--.                                                                                                               //
//    \ .-.')|    \  |  |                                                                                                               //
//    / `-' \|  ,  \ |  |                                                                                                               //
//     `-'`"`|  |\_ \|  |                                                                                                               //
//     .---. |  _( )_\  |                                                                                                               //
//     |   | | (_ o _)  |                                                                                                               //
//     |   | |  (_,_)\  |                                                                                                               //
//     |   | |  |    |  |                                                                                                               //
//     '---' '--'    '--'                                                                                                               //
//    ,---.    ,---.    .-''-.    .-_'''-.      ____    .-------.       ____    ,---.   .--..-./`)     _______      ____     .---.      //
//    |    \  /    |  .'_ _   \  '_( )_   \   .'  __ `. |  _ _   \    .'  __ `. |    \  |  |\ .-.')   /   __  \   .'  __ `.  \   /      //
//    |  ,  \/  ,  | / ( ` )   '|(_ o _)|  ' /   '  \  \| ( ' )  |   /   '  \  \|  ,  \ |  |/ `-' \  | ,_/  \__) /   '  \  \ |   |      //
//    |  |\_   /|  |. (_ o _)  |. (_,_)/___| |___|  /  ||(_ o _) /   |___|  /  ||  |\_ \|  | `-'`"`,-./  )       |___|  /  |  \ /       //
//    |  _( )_/ |  ||  (_,_)___||  |  .-----.   _.-`   || (_,_).' __    _.-`   ||  _( )_\  | .---. \  '_ '`)        _.-`   |   v        //
//    | (_ o _) |  |'  \   .---.'  \  '-   .'.'   _    ||  |\ \  |  |.'   _    || (_ o _)  | |   |  > (_)  )  __ .'   _    |  _ _       //
//    |  (_,_)  |  | \  `-'    / \  `-'`   | |  _( )_  ||  | \ `'   /|  _( )_  ||  (_,_)\  | |   | (  .  .-'_/  )|  _( )_  | (_I_)      //
//    |  |      |  |  \       /   \        / \ (_ o _) /|  |  \    / \ (_ o _) /|  |    |  | |   |  `-'`-'     / \ (_ o _) /(_(=)_)     //
//    '--'      '--'   `'-..-'     `'-...-'   '.(_,_).' ''-'   `'-'   '.(_,_).' '--'    '--' '---'    `._____.'   '.(_,_).'  (_I_)      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SFIM is ERC721Creator {
    constructor() ERC721Creator("Seasonal festivals in megaranica!", "SFIM") {}
}