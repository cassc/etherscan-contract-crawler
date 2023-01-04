// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Totems
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    oooooooooooooooooooooooodddddddddddddddddddddddddddddddddddddddddooooooooooooooooooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooooooooddddddddddddddddddddddddddddddddddddddddddddddddddddooooooooooooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooooooddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddooooooooooooooooooooooooooooooooooooooooo    //
//    oooooooooddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddooooooooooooooooooooooooooodddd    //
//    oooooodddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddooooooooooodddddddddddddddd    //
//    ooodddddddddddddddddddddddddddddxxddddddddxxxxxxxxxxxddxxxxdddddddddddddddddddoolc::;;;;;::ccccllodddddddddddddddddddddd    //
//    ddddddddddddddddddddddxxxddddddooolclloddxxxxxxxxxxxxxxxxxxxxxxxxxxdddddol:;'......      ...'',,:coddddddddddddddddddddd    //
//    dddddddddddddddddxxkkkO00OOOkxddxl'.',,,;::cldxxxxxxxxxxxxxxxxxxxxxxdl:'.        ..         .....';:codddddddddddddddddd    //
//    ddddddddddddxkkkkOOOkkkkkxxdddoodl'.';::::;;,,,:ldxxxxxxxxxxxxxxxxdl,.           ...          ........';lddddddddddddddd    //
//    dddddddddxkkkkxxdxxxxdxxxkxdoolllo:'',:coxdo:'. .'lxxxxxxxxxxxxxxxoc'            ...          ...'',;::;;:lddddddddddddd    //
//    ddddddddxxxdddxkkkkkxxdool:;,,,';ccccc::ccc,'..   .cxxxxxxxxxxxxdxd,.            .             .......,:loodddxxxxxddddd    //
//    dddddddddxxkkkkdoodol:;,'''''','...,;,'...         .okxxxxkxxxxdcl:        ....     .          ...,,;;'..';odxxxxxxxxxxx    //
//    dddddxxxxkkkdooollc:,.......''.........'::;..       ,oolccccclol;..    .,:lddl,.               .....,:cllc;;:oxxxxxxxxxx    //
//    dddddxxxxddddolc;'..............   ...cxkkkxoc,.     .;;,..',,'..    .cdxxxxxxd'                ..',,...;lddlloxxxxxxxxx    //
//    ddddddddddxdl;'..'..............     ,xkkkkkkkko:. .;:,','...':,....;okxxxxxxxx,              ......;::;'.,cdxxxxxxxxxxx    //
//    ddddddxxxdc,.',,'........ .........  'dkkkkkkkkkk:'l; 'oc..''';,.;;'ckkxkxxxxxl.               ..''...,col:,;lxxxxxxxxxx    //
//    dddddxxdc,';c:,.. ....... ..     .   .,okkkkkkkkl'',;'.co. ;d:....;;'okxkkkxl;.              ... .';;...'cdxl:lxxxxxxxxx    //
//    dddddxdc:coo;.  ....  ...            ...,clodxxx:;,..;,. .'.......;:':dlc:,.                  ...  .'::'..,oxdodxxxxxxxx    //
//    ddddddooxxc.  .''.    .                .....'',,','....,,;'.,;;,.';,. .                         ...  .;ol,..oxxxxxxxxxxx    //
//    dddddddxd:..'::.  ..                         .   .,..' ...... .. .,.                             ...   'oxl,,oxxxxxxxxxx    //
//    ddddddxd;.;od;. .'.                                . .'.  ... ........                             .,.  'oxdloxxxxxxxxxx    //
//    dddddddc;oxd,  ':.                            .,;:c:.........   .,cdxdc;,..'. .. ..  .              .c:. ,dxxxxxxxxxxxxd    //
//    dddddddooxd, .:l.                    .. .,.,llxkkkkkl.   ..     ,xkkkkkkxooo'.l; ', .,. ..        .. .ld,.:xxxxxxxxxxddd    //
//    oddddddddx:.'oo'  .  .   .  .     .' ,l.,xxxkkkkkkkkc           .dkkkkkkkxkxodx:.l: ,c..:, ..  '. .c, 'dx:;dxxxxxddddddd    //
//    oodddddddd,,dx;  ,,  '. ., .,. ', ,o,:xddxkkkkkkkkkx;           .okkkkkkxxxxxxxddxl;oo.'dc .;. ,c. cx:.:xdodxddddddddddd    //
//    ooodddddddllxo. :l. ;c. :c..o;.:d:cxxxxxxxxxxxxxxxkx,           .lkkkkkxxxxxxxxxxxxxxdlokl.,o' ;x:.;xdclxxdddddddddddddd    //
//    ooooddddddddxl.,xc.'do.'dd,,xxlokkxxxxxxxxxxxxxxxxxx'           .lkxxxxxxxxxxxxxxxxxxxxxxocdd,'oxl':xddddddddddddddddddd    //
//    ooooodddddddxo:lx:'oxxllxxdoxxxxxxxxxxxxxxxxxxxxxxxd'            ckxxxxxxxxxxxxxxxxxxddddddxdloddolodddddddddddddddddddd    //
//    ooooooodddddddddxoodxxxxxxxxxxxxxxxxxxxxxxdddddddddo.            :xxxxxxxxddddddddddddddoooooooooooooooddddddddddddddddd    //
//    looooooodddddddddddxxxxxxxddddddddddddoooooooolllllc.            ;dddddddddoooooooollllllllllllllllllllllooooooooooooooo    //
//    lloooooooodddddddddddddddddooooollllllcccccccc:::::;.            ,lllllllllllccccccccc:::::::::::::cccccccllllllllllllll    //
//    llloooooooodddddddddddddddooollccc:::::;;;;;;;;;;;;,.            .::::::::::::::;;;;;;;;;;;;;;;;:::::::ccccccccccccccccc    //
//    lllllooooooodddddddddddddddoollcc::;;;;,,,,,,,,,,,,'.            .;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::::::cccccccccccccccc    //
//    lllllloooooooddddddddddddddooollcc::;;,,,,,,,'''''''             .;;;;;;;;;;,,,,,,;;;;;;;;;;;;;;:::::::::cccccc:::::::::    //
//    lllllllloooooooddddddddddddooollcc::;;;,,,,,,,'''''.             .,;;;;;;;;;,,,,,,,,;;;;;;;;;;;:::::::::::::::::::::::;;    //
//    cclllllllooooooooddddddddddooolllcc::;;;,,,,,,,,''''.            .,;;;;;;;;;;;,,,,,;;;;;;;;;;;::::::::::::::::::::;;;;;;    //
//    ccllllllllooooooooddddddddooooollccc::;;;,,,,,,,,,,'.            .,:;;;;;;;;;;;;;;;;;;;;;;;;;::::::::::::::::::;;;;;;;;;    //
//    cccllllllllooooooooodddddooooollllcc:::;;;;,,,,,,,,'.            .,:::;;;;;;;;;;;;;;;;;;;;;;::::::::::::::::;;;;;;;;;;;,    //
//    cccclllllllloooooooooooooooooollllccc:::;;;;;,,,,,,'.            .,:::::;;;;;;;;;;;;;;;;;;;:::::::::::::::;;;;;;;;;;;,,,    //
//    ccccclllllllllooooooooooooooolllllccc::::;;;;;;;;;;,.            .,::::::::;;;;;;;;;;;;;;;;:::::::::::::;;;;;;;;;;;,,,,,    //
//    ccccccllllllllllooooooooooooolllllcccc::::::;;;;;;;,.  .          ,c:::::::::;;;;;;;;;;;;;:::::::::::;;;;;;;;;;;;;;,,,,,    //
//    ccccccccllllllllllooooooooooolllllcccccc:::::::::::;. ..          ,c:::::::::::;;;;;;;;;:::::::::::::;;;;;;;;;;;;;;,,,,,    //
//    ccccccccccllllllllloooooooooollllllccccccc:::::::::;. ..          ,cccc::::::::::;;;;;;::::::::::::::;;;;;;;;;;;;;;;,,,,    //
//    cccccccccccllllllllllllloooolllllllllccccccccc::::c;....       .. ,cccccc:::::::::::::::::::::::::::::;;;;;;;;;;;;;;;,,,    //
//    cccccccccccclllllllllllllllllllllllllllcccccccccccc;......     ...,cccccccc::::::::::::::::::::::::::::::;;;;;;;;;;;;;;,    //
//    :ccccccccccccclllllllllllllllllllllllllllcccccccccc:''....     .'.,lcccccccc:::::::::::::::::::::::::::::::::;;;;;;;;;;;    //
//    :::cccccccccccclllllllllllllloooollllllllllllcccccl:;,....    ..,,;lccccccccc:::::::::::::::::::::::::::::::::::;;;;;;;;    //
//    ::::cccccccccccclllllllllllllooooooooolllllllllllllcc,....   ...,ccllllccccccc:::::::::::::::::::::::::::::::::::::;;;;;    //
//    :::::ccccccccccccllllllllllloooooooooooooolllllllllll;.'.. .....;llllllllcccccc::::::::::::::::::::::::::::::::::::::::;    //
//    :::::cccccccccccllllllllllllooooooooooooooooooooooooo:,'.. ....;cllllllllcccccc::::::::::::::::::::cccccccccccc:::::::::    //
//    :::ccccccccccccclllllllllllooooooooooooooooooooooooool:''......:ooooolllllccccc:::::::::::::::cccccccccccccccccccccccc::    //
//    ::cccccccccccclllllllllllooooooooooooddddddoooooooooodc,,'...''cdooooolllllcccc::::::::::::ccccccccccccccccccccccccccccc    //
//    ccccccccccclllllllllllllooooooooodddddddddddddddddddddlc:,...;cldddoooollllcccc::::::::::cccccccccccccccclllllllllcccccc    //
//    ccccccllllllllllllloooooooooooodddddddddddddddddddddddddl;'.':ddddddooollllccc:::::::::cccccccccclllllllllllllllllllllll    //
//    ccllllllllllloooooooooooooodddddddddddddddddddddddddddddoc'',cxxxddddoolllccc::::::cccccccccllllllllllllllllllllllllllll    //
//    lllllllloooooooooooooooddddddddddddxxxxxxxxxxxxxxxxxxxxxxo;;coxxxxxddoollccc::::cccccclllllllllllllllooooooooooooooooooo    //
//    llllooooooooooooooddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxxxxookxxxxxxddollcccccccccclllllllooooooooooooooooooooooooooooooo    //
//    ooooooooooooddddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxkkkxxxxkkkkkkkkxdollcccccccclllloooooooooooooooooooooooooooodoooooooo    //
//    ooooooodddddddddddddddxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkxdllcccccclllooooodddddddddddddddddddddddddddddddddddd    //
//    oooodddddddddddddddxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkxdolccccclllooodddddddddddddddddddddddddddddddddddddddd    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Totem is ERC721Creator {
    constructor() ERC721Creator("Totems", "Totem") {}
}