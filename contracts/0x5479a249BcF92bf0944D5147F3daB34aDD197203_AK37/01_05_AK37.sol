// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anarkoiris7-1•1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                 //
//                                                                                                                                                 //
//    ..''''''''''''''''',,,,,''............................................................................................''''''.............    //
//    '''''''''''''''''''',,,,''............................................................................................''''''.............    //
//    ''''''''''''''''''',,,,,,,''.....'',,,,''...........................''''''.............................................'''''''...........    //
//    .''''''''''''','',,,,,,;;;,,,'''''',,,,,,,''......................''''''''''.......''''................................''''''''..........    //
//    .''''',,,,,,,,,,,,,;;:clllc:,,,'''''''',,,,,,,''''.........''''''''''''''''''......'''''''...................''''......''''''''..........    //
//    '''',,,,,,;;;;;;;cloddxOOkxoc;,,''''''',,,,,,,;;,,''''''''''''''''''''''''''''''''''''''''''.......................''''''''''''..........    //
//    ''''',,,,,;;;;;:dOOkxddddoollc:;,'''''',,,,',,;;;;,''''''''''''''''''''''''''''''''''''''''''''.................'''''''''''''''''''',;;;;    //
//    ..''''',,,,,,;:dKK000kxxdoooolc:;;,''''',,,,,,,,,,,,'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',,,,,,''',,:cc::;    //
//    ...''''''',,,;o0OxO0OxO00Okdollc:c:,,,,,,,,,,,,,,,,,,,,,''''''''''''''''','''''''''''''''''''''''''''''''''''''''','',;;:ccccc::::ccc:::;    //
//    ......''''',,;xOddxxxxk00Okxollllxo,,,,,,,;;;,,,,,,,,,'''''''',,,,,,,,,,,,''''''''''''''''''''''''''''''''',,,,,,,,;::cccllllllclllc::;;;    //
//    ........'''',;ldooddxxxxkxdoololodc,,,,,,,,,,,,,,,,,,,'''''''',,,,,,,,,,,,,,,,'''''''''''''''''''',,,,,,,,,,,,,,,;cllllccllllllcccccc::;;    //
//    ..........''',;clodxxdoooolllllclc;,;,,,,,,,,,,,,,,,,,''''''''',,,,,,,,,,,,,,,,,,,,,'''''',,,,,,,,,,,,,,,,,,,,,;:cllclllcclllccccccccc:;;    //
//    .......'''''''',:cdkOkdoodoollcc:;,,,,,,,,,,,,,,,,,''''''''''',,,,;;;;;;;;;:;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;:::cllccllllccccccc:cc:ccc::;    //
//    .......''''''''',,:coxkO00OkOxl;,,,,,,,,,,,,,,,,,,''''''''''''',,;:cccccclllc::::;;,,,,,,,,,,,,,,,,,,,,,,;:lllllllllllllccccccccccccc::;;    //
//    ........''''''''''',,;:ccc::oOOo;,,,',,,,,,,,,,,,,,''''''''''',,;::::cllllllllllllc;,,,,,,,,,,,,,,,,,,;:::cllllllllllllllccccccccccc::;;;    //
//    ...........''''''''''',,,,,',:x0d;,'''',,,,,,,,,,,'''''''''',,;::ccc:cccclllllllccc:;;,,,,',,,,,,,;,;:cllllloollllllllcclclccc::::::;;,;;    //
//    .............''''''''',,',,,,':x0o,,,',,,,,''''','''''''''',,;::cccccccccclllolllllll:;,,'.';,,,,;;;:lllloollllllllccccccccc:::;;;;;;;,,,    //
//    ............'''''''''''''''''''cOk:,,,,,,,,''''',,,,,',,,,,,;:cclllllllllllllloolloollc;;'....',;;:clloooollllllllcccc:::::::;;;;;;;;;;,,    //
//    ............''''''''''''''''''',xOc,,,,,,,,,',,;;:::;;;::;;;;:ccllllllcllllllllllloollcc:;,'.',;;;:looooollllccccccccc::::;;;;;;;;;;;;;,,    //
//    .............'''''''''''''''''',dOc,,,,'''''',::::::::cccccccllllllllcccclllllllllllllllcc:cccc::cloooooollllccccccccc::::;;;;;;;;;;;;,,,    //
//    ..........''''''''''''''''''''',dk:,,,,,'''',;:::cccccccclllllllllllccccccccllloooollllllooooooooooooloolllllcccccccc:::::;;;;;;;;;;;;,,,    //
//    ........''''''''''''''''''''''',xx;''',',,,,;:c:ccccccccllllllllollllccccccccllooooooolllooooooooooooolllllllccccccc:::;;;;;;;;;;;;;;,,,,    //
//    ........''''''''''''''''''''''';kd,'''''',,:ccccccccccccclccclllllllllcccccccloooooooolllooollllllllllcccclcccccc:::::;;;;;;;;;;;;,,,,,,,    //
//    .........'''''''''''''''''''''';kd,'''''',;:ccccccccccccccccccllllllllcccccccclllllllllllollllllcccccccccccc:::::ccc:::;;;;;;::;;,,,,,,,,    //
//    ........''''''''''''''''''''''',xk:,,,,,,;:cccllllccccccccccccccllllccccccc::cccclllllllllllllcccccccccccccc::::::::::::;;;::::;;;,,,,,,,    //
//    .'''''''''''''''''''..''''''''''ckx:,;;;:::ccllllllcc::::::ccccclllcccc::::::::::ccllllllllcccccccccccclcccc::::::::cc:::::;;;;;;;;,,,,,,    //
//    ,,,,,,,,,,,''''''''''''''''''''',ckkl:;:::clllllllcc::::::::ccclccccc:::::::::::::::cccccccccccccc:cccccccc:::::::ccccccc::::;;;;;;;;,,,,    //
//    ;;;;;;;;,,,,,'''''''''''''',,,,,,,:okkoccllllllollcc::::;;;;:::c:::::::::;;;;;;;;;;:::::ccccccccc:cccccccccc::::::cclccccc::::;;;;;,,,,,,    //
//    ;;;;;;;;;,,,,,'''''''''''',,,,,,,;;;cdkkxollllolllc:::;;;;;;;;;;::::::::;;;;;;;;;;;;;::::::::::::::::ccccccc:::::::clllllccc::;;;;;,,,,,,    //
//    ;;;;;;,,,,,,,''''''''''''',,,,,,;;;;::coxkdcclcllcc:::::;;;;;;;;;;;;;;;;;;;:c:;;;;;;;;;::::::::::::ccccccccccccccccclllllcccc::;;;;;;,,,,    //
//    ,,,,,,,,,,,,,'''''''''',,,,,,,;;;;;;:::::cl:;:cccccc::::::;;;;;;;;;;;;;;:codl,,;;;;;;;;;;::::::::::ccllllllllllllllllllcllccc::::;;;;;;,,    //
//    ,,,,,,,,,,,''''''',,,,,,,,,,;;;;;;;;;:::::::::ccc:::::::::;;;;;:::ccc::coxxo;..':c::::::::::::::cccclllllllcccllloooollccccc::::::;;;;;;;    //
//    ,,,,''''''''''',,,,,,,,,,;;;;;;;;;;;;;;:::::ccc:::::::::;;;::cccccccccccoxkOkc..'clccccccccclllllllllllllcccccclllooolccccc::::::::;;;;;;    //
//    ,,'''''''''''',,,,,,,,,,;;;;;;;;;;;;;;::::cclll;..,;;;;;;:;;;;:ccccccc::cloxOx' .;lolllllllloolllllooooolccccccccllllcccccc:::::::::;;;;;    //
//    ,'''''''''''',,,,,,,;;;;;;;;;;;;;;;;;;;::::clllc. .';;;::;,,'..,:ccccccccc::;'...oxdolllllllllllcllllllllccc:::ccclcccllllcc::::::::::;;;    //
//    '''''''',,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::cccl:. .':cc:,;cl:,...;cccc:;'... ..cOK0xolllllccccccccccccccccc::cccccccccllclc:::::::::::::    //
//    '''''',,,;;;;;;;;::::;;;;;;;;;;;;;;;;;;;;;:::::cc;. ..,::;;codoc;'':c;'..  ..,:ccokK0xlllccccccc:::::::::::ccccccc:ccllcc:c::;;;:::::::::    //
//    ''',,,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::::::ccc:'....''.':::cc,....    .,cllllllx0Kxllcccccc::::::::::::::::ccc::cccc:::::;;;:ccccccll    //
//    ,,,,,,,;;;;;;;::::::;;;;;;;;;,;;;;;;;;;;;:::::cccllolc:,.. ...........  ..:llllllllox00dlcccccc:::::::::::::::::::::::::::;:::::::c::clll    //
//    ,;;;;;::::::::::::::::;;;;;;;;;;;;;::::::::::cccclllodxdl;............. .:lllllllllllx0klccccc::::::::::::::;;;;;;::::::;;;;;:::::::::ccc    //
//    ;;;::::::::::::::::;;;;;;;;;;;;;::::::::cccc::cccclloodddxo:........... .clllcccccccclO0dcccc::::::;;;;:::;;;;;;;;;;;;;;;;;;;;;;;;;;:::::    //
//    ;;;:::::;;;;;;;;;;;;;;;;;;;;;;;:::::::::ccccc:::ccllooooooddc.......... .cllcccccccccco0kl::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::::ccccccccccloddooooooool,...... ...'clllccc:::ccccd0xc:::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::::ccccccclllodxxddooooooll:.     .   ,llllccc:::::::cd0kl:::;;;;;;;;;;;;;;::;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;:;;:::::::::::;;;;;;;;;;;;;;:::::ccccccloddddddddoooolll:..'''.....,llllccc:::::::::oOOxl:::;;;::;;::::::::cclllc:::::::::::::::::::    //
//    :::::::::::::::::::::::::::::::::::::::::clooooooooooollllccc,..........'cllccc:::::::::::cdkOkdl:::::;;::::clodxkOOkdolccccc::::::::::::    //
//    clllcccc:ccccccccc::::::::::::::::::::::colccclllllllccccccc,.          .:lcccc::::::::::::::ldkOkxolc::::cdkkxxddddoollllcc:::cccccccc::    //
//    lllllcccclcccccccccccccccccccc:::::::::llc::::ccccccccccccc:.           .;lccccccccccc::::::::::coxkkxxdookK0xdxxxxxdoooolllccccccccccc::    //
//    llllccccllllcclllllllllllcccccccc:::::llc:::::ccccccccccccc,.           .,clcccccccccccccccccccc:::ccldxk0KOkxkkkkOOkxdoodooolccccccccc::    //
//    llllllllooooooooooollllllcccc::::::::cll::::::ccccccccccccc'..          .'ccccccccccccllllllllllccccccccoO0kkOOkkOKK0Oxdddodkdcccccccc:::    //
//    llloodddxxxxddddoolllllccccc:::::::::clcc::::::ccccccccccccc:;.. .......'cccccccccccccclllloooollllllllloxkkk0K0O0KK0Oxdododkocccccccc:::    //
//    oodddxxxxxxddddoollcccccc:::::::::;;:clc:::::::cccllllccccclool;';ccc:,';cccccccccccccccccccccllllllllllloxk0XXKOkkkxddddooooccccccc::::c    //
//    lloooooooooollllllccllcc::cccccc:::;;:c:;::::cccccccccccccclodolcldll:,,:cccccccccccccccccccccccccccccllllloxOKKK0Okkxxddlllcccllccc::::c    //
//    ::cccccccccccccccclllcccccccccccc:;,',;,'';cccccc::::ccccccloddlcodol:',cccccccccccccccccccccccccccccccccccllodk0KKKK0xolcccclllllcccc::c    //
//    ;;;;::::cccc::ccccccccccccccccccc;'.';::,..,ccc::::::::ccccloxxoclxol:';ccccccccccccccccccccccccccccccccccccccclodxxdocccccclllccllcccccc    //
//    ;;;::::cccc:::::::::cc:cccccccc:c;'.....''';::ccccccccclllllldxdloxoc;';:::cccclllllllccccccccccccccccccccccc:ccccc:::::cccllccccccc:::::    //
//    ::::::ccllc::;;;:::::::::::::::::::;;;,,;;::::::ccccclllllllloxdldxl;,,:ccccllllllllccccccccccccccccc::::::::::::::::::::cccccccc::::;:::    //
//    :::::::clllc:;;;;;:::::::::::::::;::;;;;;;::::::ccccccc:::clloxdcox:'';cccllooolllccccccccc::::::::::::;;;;;:;;;;;;;;;;;::::::::;;;;;;;::    //
//    ;;;::;::ccc::;;;;;::::ccc::::::;;;;;;;,;;:::cccccccc:::;;:clooddlod;.':llllllllcccc:::::::::::;;;;;;;;;;;;;;;;;;;,,,,,;;::c:::;;;;;;;;;;;    //
//    ,;;;;;;;;:::::;;:::::cccccc::::;;;;;;;;::::cccccccc:::;;::cllldxooo:'',cccccccc::::::::::::;;;;;;;;;;;;;;;;;;;;;;,,,,;;:cccc:::;;;;,,,,,,    //
//    ,,;;;;;;;;;;::;;:::::cccccc::::;;;;;;;;::::clccc::::::::::::::lxdlddo:',::::::::;;;;::cccc::;;;;;;;;;;;;::::;;;;;,,,,;:cclcc:::;;;;,,,,,,    //
//    .''',,,;;;;;;;;;;;;::cccllc::;;;;;;;;;;;::clllcc:::;;;;;;;;;;;cddlcdxc';cc:ccc:;;;;:cclllcc:::;:;;;;;;;::::;;;;;,,,,,;:::::;;::;;;,,'''''    //
//    ........''''',,,;;;;;::ccc::;;;;:;;::;;;;;;:::::;;;,;;;;,,,,,;;ldl;coc,;c::c::;;;;;::cccc::::;;;;;,,,;;:::::;;;;;,,,;,,,,,,,,,'''''......    //
//    .....................''''''',''''''..........''''','''.......',:dl:cc;;cc;,'......'''',,''''...........''''''''''''''.........',,'.......    //
//    ..........;cc:;,'...''.....''''....................'',,;:clooxkkkllol;;OK0Okxool:;'.........................''''.....'''...',;;:lc;......    //
//    .........':c;'';:,.',;;;;;;,,''.''''........',,;:::codxkkO0000KK0dldxc:xKNNNNNNNXKOkdolc;,'...........'''''.'',,,;;;:;;,'.'::'.';;'......    //
//    ...........',,,;;...'..,;,,,;;;;,,,,''''';:cloooc;;:coddxk000000Oo:d0xookKNNNNNNNXXKKKK00kdc,......''',,,,,;;;;,,,;;'..'...';,,'.........    //
//    ........................'''',,,;;;:;;;;;;;;;;;:;,'',;:lodxkO0OkkoldOK0kdd0XXXXXXKOkxolc:;,'''',;;;;;:;;;;;;;,','''''.....................    //
//     ... ...   .............'''.'.'''',,,;;,'',',::;,''''',:cldk0Okxdk0KXXNKK00Okxoc:;'....'';;:;,'''',;:;,,,''''.'.''''.......... ...   ....    //
//         .. ..  .....................'''',;,'''.''.',,'','.''',:ldxxxxkkOkxoc:;,'...'''','',,,'.,'.''',;,'''''................... .    .   .     //
//        . ..    ..........................''''''''................''',,'''......................',''''','............................       .    //
//        . ...................'.......................................................................................''.................... .    //
//            .................'.......................................................................................''...................       //
//                                                                                                                                                 //
//                                                                                                                                                 //
//                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AK37 is ERC721Creator {
    constructor() ERC721Creator(unicode"Anarkoiris7-1•1", "AK37") {}
}