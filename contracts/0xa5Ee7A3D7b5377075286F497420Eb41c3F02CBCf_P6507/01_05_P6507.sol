// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Punk #6507
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXd;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXc                                   lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXOxddd,                                   ;dddx0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXc          ....                               lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKc          ....                               cKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXd;,,,.       ..                                    .,,,;xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc          ....                                         lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXOdddd,            .                                          ;ddddOXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXKc                                                                 lXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXc                                                                 lXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXc                                                                 lXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXc                                                                 lXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXc                                                                 lXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXc                                                                 lXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXc                                                                 lXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXc                         ....                                    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXc                        .',''.                                   lXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXc                    .....',''.                ....          .,,,;xXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXc                   .,,,,,''''.               .,,,,,''''.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXc                   .,,,,,''''.               .,,,,,',''.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXc               ....',,,,,,,,'.....       ....',,,,,,,,'.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXc              .','',,,,,,,,,,,',,'.     .','',,,,,,,,,,.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXc              .'''''.....'''''',,'...   .''''......''''.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXc              .''''.    .....''''''''''''''''.    ......    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXc              .''''.    .....'',,'',,'''''','.    ......    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXc              .'',''....''''''''''''''''''''''....'''''.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXc              .'''',,,,,,'''''''''''''''''''',,,,,,'','.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXc             ..'''',,,,,,''''''''''''''''''',,,,,,,',,'.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXc         .''''''''''''''''',,''''''''''''''',''''''''''.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXl         .''''''''''''''''''''''''''''''''''''','''''''.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXX0xdxd,    .''''''''''''''''''''''''..        ..','''''''.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .''''''''''''''''''''''''.          .','''''''.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .''''''''''''''''''''''''. ..    ....'''''''''.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .'''''''''''''''''''''''''''''''''''''''''''''.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .'''''''''''''''''''''''''''''''''''''''''''''.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .'''''''''''''''''''''''''''''''''''''''''''''.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .''''''''''''''''''','''''''''''''',''''''''''.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .'''''''''''''''',',.................'''''''''.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .'''''''''''',''''''.               .'''''''''.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .'''''''''''''''''''.               .'''''''''.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .'''''''''''''','''''................','',''''.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .'''''''''''''''''''''''''''''''''''''''''''''.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .''''''''''''''''''''''''''''''''''''''''.....',;;;xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .''''''''''''''''''''''''''''''''''''''''.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .''''''''''''''''''''''''''''''''''''''''.   .lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .''''''''''''''.                        .;xxxx0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .'''''''''''','.                         lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .''''''''''''''.    .,,;;;,,,,,,,,,,,,;;;xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .''''''''''''''.    cXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .''''''''''''''.    cXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .','''''''''','.    cXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .''''''''''''''.    cXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXc    .,,,,,,,,,,,,,,.    lXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract P6507 is ERC1155Creator {
    constructor() ERC1155Creator("Punk #6507", "P6507") {}
}