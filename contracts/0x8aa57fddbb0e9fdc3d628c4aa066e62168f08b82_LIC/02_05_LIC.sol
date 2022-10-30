// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Living In Colours
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    ::::::::::::::::::::::::::::::::::::::::::::::::      //
//    :::::::::::::::::::::::::::::::::::::::::::::::::;    //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::    //
//    :::::::::::::::::cccc::::::ccccc::::::::::::::::::    //
//    :::::::::::::::ccc;'.........',;cccc::::::::::::::    //
//    :::::::::::::ccc:................',:ccc:::::::::::    //
//    ::::::::c:ccccc;.....................;ccc:::::::::    //
//    cccccccccccccc;.......................'ccc::::::::    //
//    ccccccccccccc;.........................,lcc:::::::    //
//    cccccccccccl;..........................'clc:::::::    //
//    cccccccccclc'..........................'clcc::::::    //
//    cccccccccll,...........................,cccccccc::    //
//    ccccccccclc............................:lccccccccc    //
//    cccccccccl;...........................;lcccccccccc    //
//    cccccccccl;..........................,clcccccccccc    //
//    ccccccccll;.........................'clccccccccccc    //
//    ccccccccll,........................'clcccccccccccc    //
//    cccclllloc.......................,:lolcccccccccccc    //
//    ccclllllll:...................;coxkxoccccccccccccc    //
//    llllllllllllc::;...........;coddxxdl:;:::ccccccccc    //
//    lllllllllllllllol,......;codolllddoc:;;;:::::::::c    //
//    cllllllllllllllccc,...,lddollc;:ccc:;:::::::::;;;:    //
//    cccccccclllllcccloo;':odllllc::;;;;;:::;;;;;;;;;;;    //
//    ccccccllllllc;:loollcclllllc:::;;;;;:c;;;;;;;;;;;;    //
//    ccclllllool:;;;:ccolcodxddl:::;;;;;:::;,,;;;;;;;;;    //
//    lllloooddl::::::::clooodl::::c:;;;;::;,,,;;;;:c:;;    //
//    ooodddddl::cllloocclcldlcooc;;:::;:lc;;,,,,;;:clc:    //
//    ddddxxdc::cllclddc::cxxccool:;;;;;clc;;;;;;,;;clcc    //
//    ddxxxoc:::::;:cdo:;:lxdc::cclc:;;;:c::;;;::;;;;::;    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract LIC is ERC721Creator {
    constructor() ERC721Creator("Living In Colours", "LIC") {}
}