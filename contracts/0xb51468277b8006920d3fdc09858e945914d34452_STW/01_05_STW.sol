// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Saintwave
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::::ccccccccccccccc::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::cccllooooddddddddddddooolllccc:::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::ccloodxxkOO000KKKKKKKKKK000Okkxddoolcc:::;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;::ccloodxOO0KXXNNNNNNNNNNNNNNNNNNNNXXK0Okxdoolcc::;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;::cclodxk0KXNNNNNNNNNKxlxKNNNNNNNNNNNNNNNNNXXKOkxdolc::;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;::clodxk0KXNNNNNNNNNNNXk;..c0NNNNNNNNNNNNNNNNNNNNXK0kxollc::;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;::clodkOKXNNNNNNNNNNNNNNKo'.,,oXNNNNNNNNNNNNNNNNNNNNNNXKOxdolc::;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;:clodk0KNNNNNNNNNNNNNNNNNO:',;,lKNNNNNNNNNNNNNNNNNNNNNNNNNKOxdolc:;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;::codxOKNNNNNNNNNNNNNNNNNNXx;,;;,l0NNNXXXKOOKNNNNNNNNNNNNNNNNXKOxolc::;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;:clodOKXNNNNNNNNNNNNNNNNNNNXd,,:;,:xkkxol:,.;ONNNNNNNNNNNNNNNNNNX0kdolc:;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;:cloxOXNNNNNNNNNNNNNNNNNNNNN0oc:;'...'...  .;kNNNNNNNNNNNNNNNNNNNNNKOxolc:;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;:cldx0XNNNNNNNNNNNNNNNNNNNNNKxoc;'......',;lkXNNNNNNNNNNNNNNNNNNNNNNNXOxolc:;;;;;;;;;;;;    //
//    ;;;;;;;;;;;:cldx0XNNNNNNNNNNNNNNNNNNNNKkdc;,''..cxkOO0XNNNNNNNNNNNNNNNNNNNNNNNNNNNX0xolc:;;;;;;;;;;;    //
//    ;;;;;;;;;;:clox0XNNNNNNNNNNNNNNNNNNX0xdl;'''...;0NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXOxolc:;;;;;;;;;;    //
//    ;;;;;;;;;::coxOXNNNNNNNNNNNNNNNNNNN0xoc:;,'....oXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKkdoc:;;;;;;;;;;    //
//    ;;;;;;;;;:cldkKNNNNNNNNNNNNNNNNNNN0kkl:c:;'.'',kNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN0xdlc:;;;;;;;;;    //
//    ;;;;;;;;::loxOXNNNNNNNNNNNNNNNNNNXkkkllc:;;looox0XNNNNNNX0kOKNNNNNNNNNNNNNNNNNNNNNNNNXOdoc:;;;;;;;;;    //
//    ;;;;;;;;:clokKNNNNNNNNNNNNNNNNNNN0kkooooolllloddxkOOKNNKd;;lx0NNNNNNNNNNNNNNNNNNNNNNNX0xolc:;;;;;;;;    //
//    ;;;;;;;;:cldkKNNNNNNNNNNNNNNNNNNXkddlcllc:;;,..';cllx0XOc:cooxXNNNNNNNNNNNNNNNNNNNNNNNKkdlc:;;;;;;;;    //
//    ;;;;;;;;:codOXNNNNNNNNNNNNNNNNNNkokklclddollllll::;,,,clccodooKNNNNNNNNNNNNNNNNNNNNNNNKkdlc:;;;;;;;;    //
//    ;;;;;;;;:codOXNNNNNNNNNNNNNNNNN0kOkllddl;',,,:oxkdoolc:;;;;::lOXNNNNNNNNNNNNNNNNNNNNNNKkdlc:;;;;;;;;    //
//    ;;;;;;;;:cldOXNNNNNNNNNNNNNNNNK0Okxdoc;'......',cdxdodkkxc'..:d0NNNNNNNNNNNNNNNNNNNNNNKkdlc:;;;;;;;;    //
//    ;;;;;;;;:cldkKNNNNNNNNNNNNNNN00Odxkoc:,.........':lx0xONKl'..,cx0NNNNNNNNNNNNNNNNNNNNNKkdlc:;;;;;;;;    //
//    ;;;;;;;;:clox0NNNNNNNNNNNNNNNOdxxdccc:,'........;lodkxkXXx:,'';okKNNNNNNNNNNNNNNNNNNNX0xol::;;;;;;;;    //
//    ;;;;;;;;;:codOXNNNNNNNNNNNNNNkdxl:clc;,............';okKXOo;'.':dOKNNNNNNNNNNNNNNNNNNXOdoc:;;;;;;;;;    //
//    ;;;;;;;;;:cldk0XNNNNNNNNNNNN0dddcloc;'........  .....'lkkxo;....lkOKNNNNNNNNNNNNNNNNX0xolc:;;;;;;;;;    //
//    ;;;;;;;;;;:codOKNNNNNNNNNNNN0OOo:;'..........  ... ...,lool,..'.,xOOXNNNNNNNNNNNNNNNKkdlc:;;;;;;;;;;    //
//    ;;;;;;;;;;:cloxOXNNNNNNNNNNNKKXx;........''...........;ll:,.....'l00KNNNNNNNNNNNNNNXOxol::;;;;;;;;;;    //
//    ;;;;;;;;;;;:clox0XNNNNNNNNNNNK0Ol,'.',;::cc,.........,okc,.......;xKKXNNNNNNNNNNNNXOxolc:;;;;;;;;;;;    //
//    ;;;;;;;;;;;;:cloxOXNNNNNNNNNNXkddlcc::cc:;cl;.......'lxl;''......'cO0KNNNNNNNNNNNXOxolc:;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;:cloxOKNNNNNNNNNNXkxdc;,,'''',:lc,.....'ox:,''......';ox0NNNNNNNNNNKOxolc:;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;::codk0XNNNNNNNNNXkxxc,''......;c:'....,lc,''.....'';:l0NNNNNNNNX0kdocc:;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;::cloxOKXNNNNNNNNXkxxc,'.......,;:;''...;:,'....'';ooxXNNNNNNNKOxolc::;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;::cldxOKXNNNNNNNXOxxl,''.....'',;;;'..':;''..'',codKNNNNNNKOxdocc:;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;:ccodxO0XNNNNNNNOxxl;'.......'''','..;:,'..'':od0NNNNXKOxdolc:;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;:cclodk0KXNNNNNKkxo:'.........'''..';,'.'';lxOXNXK0kxollc::;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;::clooxkO0KXNNXOkxc'..................'';oOKK0kxdolc::;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;::ccllodxkO0KK0Oxo:''''..............';lxxdoolcc::;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::cclloddxkkxdddl;,''''..........,clolccc::;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::cccllooc;:c:;;,'............:c::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::::;....................;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,....................';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,.....................,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'.....................,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'.....................';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,......................';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract STW is ERC721Creator {
    constructor() ERC721Creator("Saintwave", "STW") {}
}