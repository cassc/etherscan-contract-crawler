// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Forget the Moment
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::::::::::::::::::::::::::::::    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::::::::::::::::::::::::::::::::::::    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::::::::::::::::::::::::::::::::::::::::    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::::::;;;;;::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ;;;;;;;;;;;;;;;;;;;;:::::;;;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ;;;;;;;;;;;;;;;;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    ;;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::ccc    //
//    :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::ccccccc    //
//    :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::ccccccccccccccccccc    //
//    :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::cccc:::cccccccccccccccccccc    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::cccccccccccccccccccccccccccc    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::cccccccccccccccccccccccccccccccccccccccccccccc    //
//    ::::::::::::::::::::::::::::::::::::::::::cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ::::::::::::::::::::::::::::::::::::cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ::::::::::::::::::::::::::cccccccccccccccccccccllllccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    :::::::::::::::::::cccc::cccccccccccccccccccccoxkxxdlccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ::::::::::cccccccccccccccccccccccccccccccccccldxkOOOdccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccclodxxdlccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccllllll    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccclllllllllll    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccllllllllllllllllllll    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccclllllllllllllllllllllllll    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccllllllllllllllllllllllllllllllllllllll    //
//    ccccccccccccccccccccccccccccccccccccccccccccccllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    ccccccccccccccccccccccccccccccccccccllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    ccccccccccccccccccccccccccllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    ccccccccccccccccccllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    ccccllclllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllloooooo    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllollllooooooooooooooooooo    //
//    lllllllllllllllllllllllllllllllllllllllc::;;,,,'''''''',;:clolloooollooooooooooooooooooooooooooooooo    //
//    llllllllllllllllllllllllllllllllllllc:,.......           ..';clooooooooooooooooooooooooooooooooooooo    //
//    lllllllllllllllllllllllllllllllc;;'.......                 ...',;clooooooooooooooooooooooooooooooooo    //
//    llllllllllllllllllollllllllc;,........                        ....',;clooooooooooooooooooooooooooooo    //
//    llllllllllllllllooooooolc;'.....  ..                              ....',;:looooooooooooooooooooooooo    //
//    lllllllloooooooooooool:'........                                        ...;cooooooooooooddddddddddd    //
//    ooooooooooooooooooool;.  .....                                            ...,lddddddddddddddddddddd    //
//    oooooooooooooooooooo:.   .....                                               .'coddddddddddddddddddd    //
//    ooooooooooooooooooo:..    .. .                                                ..;odddddddddddddddddd    //
//    oooooooooooooooooo:..                                                           .;oddddddddddddddddd    //
//    ooooooooooooooooo:..                                                             .;odddddddddddddddd    //
//    oooooooooooooddoc'.                                                               .:dxdddddddddddddd    //
//    oooooddddddddddl,..                                                               .'oxxxxxxxxxxxxxxx    //
//    ddddddddddddddo;.                                                                  .:dxxxxxxxxxxxxxx    //
//    ddddddddddddddc..                                                                  .'oxxxxxxxxxxxxxx    //
//    dddddddddddddl..                                                                    .,oxxxxxxxxxxxxx    //
//    dddddddddddddc.                                                                      .:xxxxxxxxxxxxx    //
//    ddddddddddddo;..                                                                     .:xxxxxxxxxxxxx    //
//    dddddddddxxd:.                                                                       .;xkkkkkkkkkkkk    //
//    xxxxxxxxxxxxl'.                                                                      .lkkkkkkkkkkkkk    //
//    xxxxxxxxxxxxl'..                                                                     .cxkkkkkkkkkkkk    //
//    xxxxxxxxxxxo,.                                                                        .,cxkkkkkkkkkk    //
//    xxxxxxxxxxl'.                                                                           'dkkkkkkkkkk    //
//    xxxxxxxxxo'.                                                                           .;xkkkkkkkkkk    //
//    xxxxxxxxkd;.                                                                           .'okkkkOOkkkk    //
//    xkkkkkkkxo,..             ..                                                            ..ckOOOOOOOO    //
//    kkkkkkkko,.  .            ..                                                             .;xOOOOOOOO    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FTM is ERC721Creator {
    constructor() ERC721Creator("Forget the Moment", "FTM") {}
}