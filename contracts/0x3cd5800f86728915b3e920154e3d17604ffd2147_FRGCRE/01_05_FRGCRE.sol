// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FROGCREATOR
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//                _  .-')                                                         //
//              ( \( -O )                                                         //
//       ,------.,------.  .-'),-----.   ,----.                                   //
//    ('-| _.---'|   /`. '( OO'  .-.  ' '  .-./-')                                //
//    (OO|(_\    |  /  | |/   |  | |  | |  |_( O- )                               //
//    /  |  '--. |  |_.' |\_) |  |\|  | |  | .--, \                               //
//    \_)|  .--' |  .  '.'  \ |  | |  |(|  | '. (_/                               //
//      \|  |_)  |  |\  \    `'  '-'  ' |  '--'  |                                //
//       `--'    `--' '--'     `-----'   `------'                                 //
//               _  .-')     ('-.   ('-.     .-') _                _  .-')        //
//              ( \( -O )  _(  OO) ( OO ).-.(  OO) )              ( \( -O )       //
//       .-----. ,------. (,------./ . --. //     '._  .-'),-----. ,------.       //
//      '  .--./ |   /`. ' |  .---'| \-.  \ |'--...__)( OO'  .-.  '|   /`. '      //
//      |  |('-. |  /  | | |  |  .-'-'  |  |'--.  .--'/   |  | |  ||  /  | |      //
//     /_) |OO  )|  |_.' |(|  '--.\| |_.'  |   |  |   \_) |  |\|  ||  |_.' |      //
//     ||  |`-'| |  .  '.' |  .--' |  .-.  |   |  |     \ |  | |  ||  .  '.'      //
//    (_'  '--'\ |  |\  \  |  `---.|  | |  |   |  |      `'  '-'  '|  |\  \       //
//       `-----' `--' '--' `------'`--' `--'   `--'        `-----' `--' '--'      //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


contract FRGCRE is ERC1155Creator {
    constructor() ERC1155Creator("FROGCREATOR", "FRGCRE") {}
}