// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shape the Future
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    oxOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxooxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdodkOOOOOOOOOOOOOOOOOOOOOOOOOOOOkx    //
//    lloxOOOOOOOOOOOOOOOOOOOOOOOOkxdoolloxkOOOOOOOOOOOOOOOOOOOOOOOOOxdoollldkOOOOOOOOOOOOOOOOOOOOOOOOkxoo    //
//    llllokOOOOOOOOOOOOOOOOOOOOkxdoooolclloxkOOOOOOOOOOOOOOOOOOOOOxdoooollllldkOOOOOOOOOOOOOOOOOOOOkdoooo    //
//    lllllloxOOOOOOOOOOOOOOOOkxdoooooolcllcloxkOOOOOOOOOOOOOOOOkxdoooooolcllllldkOOOOOOOOOOOOOOOOkddooooo    //
//    lllllllloxOOOOOOOOOOOOkxdoooooooolllllllloxOOOOOOOOOOOOOkxdoooooooolcllllllldkOOOOOOOOOOOOkdoooooooo    //
//    lllllllclloxOOOOOOOOkxdoooooooooolllllllllloxkOOOOOOOOOxdoooooooooolcllllllclldkOOOOOOOOkxdooooooooo    //
//    lllllllllllloxOOOOkxdoooooooooooolllllllllllloxkOOOOOxdoooooooooooolcllllllllclldkOOOOkxoooooooooooo    //
//    llllllllllllcloxkxdoooooooooooooollllllllcllllloxkkxdoooooooooooooolcllllllllllllldkkddooooooooooooo    //
//    llllllllllcllc:,,:ooooooooooooooollllllllllllllc;,,:loooooooooooooolcllllllllllllc;,;coooooooooooooo    //
//    lllllllllclc:,....,cooooooooooooolllllllllcllc;.....':loooooooooooolclllllllllcc;'....;coooooooooooo    //
//    lllllllclc:,........,cooooooooooolllllllllcc;'........':loooooooooolcllllllclc;'........;coooooooooo    //
//    lllccllc:,............,:ooooooooollllllll:;.............';ldooooooolllcllllc;'............;coooooooo    //
//    lllllc:,................,cooooooollllllc;'................';loooooolllcllc;'................;coooooo    //
//    lcll:,....................,cooooollllc;.....................';loooolcclc;'....................;coooo    //
//    lc:,........................,cooollc;'........................':loollc;'........................;coo    //
//    :,............................,:lc;.............................';cc;'............................;c    //
//    cllllllllllllllllllllllllllllllllclllllllllllllllllllllllllllllllllcclllllllllllllllllllllllllllllll    //
//    odkOOOOOOOOOOOOOOOOOOOOOOOOOOOxdoldkOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxoooxOOOOOOOOOOOOOOOOOOOOOOOOOOOkxd    //
//    llldkOOOOOOOOOOOOOOOOOOOOOOOxdooollloxOOOOOOOOOOOOOOOOOOOOOOOOkdooollloxkOOOOOOOOOOOOOOOOOOOOOOkxdoo    //
//    llclldkOOOOOOOOOOOOOOOOOOkxdooooollllloxOOOOOOOOOOOOOOOOOOOOkdooooollllloxkOOOOOOOOOOOOOOOOOOkxdoooo    //
//    lcllccldkOOOOOOOOOOOOOOOxdooooooolcllllloxOOOOOOOOOOOOOOOOkddoooooolcllllloxOOOOOOOOOOOOOOOkxdoooooo    //
//    lllllllcldkOOOOOOOOOOOxdooooooooolcllllclloxOOOOOOOOOOOOkdooooooooolcllllllloxkOOOOOOOOOOkxdoooooooo    //
//    llllllllllldkOOOOOOOxdooooooooooolclllllllllokOOOOOOOOkdooooooooooolcllllllllloxkOOOOOOkxdoooooooooo    //
//    lcllllllllllldkOOOxdooooooooooooolcllllllllllloxOOOOkxooooooooooooolclllllclllcloxkOOkxdoooooooooooo    //
//    lllllllllcllclloddooooooooooooooolllllllllllllllodddooooooooooooooolclllllllllllclooddoooooooooooooo    //
//    lllllllllccllc;..;coooooooooooooolllllllllllllc:'..,coooooooooooooolclllllllllllc:,.':looooooooooooo    //
//    lllllllllclc;......;coooooooooooollllllllcclc;'......,coooooooooooolcllllllcclc:,.....':looooooooooo    //
//    lllllllllc;..........;coooooooooolllllllllc;'..........,:oooooooooolllllllllc:,.........';ldoooooooo    //
//    lllllllc;'.............;codoooooolllllllc;'..............,coooooooolllllllc:,.............';looooooo    //
//    llcllc;'.................;coooooollllcc:'..................,coooooolllclc:,.................';looooo    //
//    lllc;'.....................;coooolllc:'......................,coooolllc:,.....................':looo    //
//    lc;'.........................;coolc;'..........................,:oolc:,.........................';ld    //
//    :,............................':lc,'............................';cc;'............................,c    //
//    ldxxxxxxxxxxxxxxxxxxxxxxxxxdxxdolloxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddolodxxxxxxxxxxxxxxxxxxxddxxxxxxxdo    //
//    loxkOOOOOOOOOOOOOOOOOOOOOOOOOkdoolldkOOOOOOOOOOOOOOOOOOOOOOOOOOkxdolloxOOOOOOOOOOOOOOOOOOOOOOOOOOxdo    //
//    lcloxkOOOOOOOOOOOOOOOOOOOOOkxdooollcldkOOOOOOOOOOOOOOOOOOOOOOkxdooollcloxOOOOOOOOOOOOOOOOOOOOOOxdooo    //
//    llllloxkOOOOOOOOOOOOOOOOOkxoooooolllllldkOOOOOOOOOOOOOOOOOOkxdooooolclllloxOOOOOOOOOOOOOOOOOkxdooooo    //
//    llllccloxkOOOOOOOOOOOOOkxoooooooolclllllldkOOOOOOOOOOOOOOkxdooooooolclllclloxOOOOOOOOOOOOOOkdooooooo    //
//    llllllllloxkOOOOOOOOOkdoooooooooolllllllllldkOOOOOOOOOOkxdooooooooolclllllclloxOOOOOOOOOOxdooooooooo    //
//    lllllllllclodkOOOOOkxdooooooooooolllllllllllldkOOOOOOkxdooooooooooolcllllclllcldxOOOOOOxdooooooooooo    //
//    llllllllllclloxkOkxoooooooooooooolllllllllllllldkOOkxdooooooooooooolclllllllllllloxOOxdooooooooooooo    //
//    llllllllllllllccclooooooooooooooolllllllllllcllcccclooooooooooooooolclllllllllllllcccooooooooooooooo    //
//    llllllllllclc;'..':looooooooooooollllllllllclc:,....;looooooooooooolcllllllclllcc;'..,:ooooooooooooo    //
//    lllllllcclc;'......';looooooooooollllllllllc:,........;cooooooooooollllllllcllc;.......,cooooooooooo    //
//    llllllllc;'..........':looooooooollllllllc:,............;cooooooooolccllllllc;...........,cooooooooo    //
//    llllllc;'..............':looooooolcllllc:,................;looooooolllllllc;...............,cooooooo    //
//    llllc:'..................':looooolcllc:,....................;cooooolccllc;...................,cooooo    //
//    llc;'......................';looollc:,........................;cooolclc;'......................,cooo    //
//    c;'..........................':lol:,............................;colc;'..........................,co    //
//    ,..............................,c;'..............................':c'..............................;    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SHAPE is ERC721Creator {
    constructor() ERC721Creator("Shape the Future", "SHAPE") {}
}