// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HENBO HENNING
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//     ('-. .-.   ('-.       .-') _ .-. .-')                   //
//    ( OO )  / _(  OO)     ( OO ) )\  ( OO )                  //
//    ,--. ,--.(,------.,--./ ,--,'  ;-----.\  .-'),-----.     //
//    |  | |  | |  .---'|   \ |  |\  | .-.  | ( OO'  .-.  '    //
//    |   .|  | |  |    |    \|  | ) | '-' /_)/   |  | |  |    //
//    |       |(|  '--. |  .     |/  | .-. `. \_) |  |\|  |    //
//    |  .-.  | |  .--' |  |\    |   | |  \  |  \ |  | |  |    //
//    |  | |  | |  `---.|  | \   |   | '--'  /   `'  '-'  '    //
//    `--' `--' `------'`--'  `--'   `------'      `-----'     //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract HENBO is ERC721Creator {
    constructor() ERC721Creator("HENBO HENNING", "HENBO") {}
}