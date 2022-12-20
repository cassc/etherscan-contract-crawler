// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ACKSTRACT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//    :::::::;;:;;::::::::::c:::ccclc:::cc:;;;;::clc'.':cccllllollllloolcc:;;;:c:cc:,;:;;:ccc::cllccc:cloollllc:cc:';cccclllccc::cllllcccc:::cllllcclc:cllllllcccccc::cllc:::ccccccccc:::c    //
//    ::::;;:::::::::::::::::::::::lcccc:::;;;;;::cc:;:ccccllllllll:cllcclcc:::::cc:::::;::cc::clcclllllcllccc::cc:::c:cclccccllllolcllllcclc::cc::ccccccccllcccccccccclc:cc::cccccccccccc    //
//    ;::;;:ccc::::ccccc:::c:::ccccclc::,;cc::::::::ccclolccclllc::cc:::ccccc:;;;:;;;::::;:cc::::clllllllllccc::c;;ccclcccccllllolllollllc:,;:ccc:c:;:cccccccccclccccc::;;:::;:::::ccccccc    //
//    ;::::ccccc:c::cc:c:cccc::::cccc::c::ccc::::::cc:::clllclc:;;;:::,;clcccc:::c;:cccc:cccc:::;::;:lollloll:;::;;:::lccllcllcccllllllllc::loollllcccccclllcccccccc::::;,,;;;:::::::ccccc    //
//    ,;:cccc::c::;;::;ccccccccc:::::;:cc:ccc::::;;cc::cllcclc,..,::::;:llcclolccc:cccc::cllccc:::::clllollll:;;;,,;;;::clccccc:coolllllolcollooooloolccclllccccc:ccc::;;;;::::;;:::::::cc    //
//    ;;::::::;;::::::::::cccccc:::;;:cc::ccc::cc::clolloolccc,.';:::;;clcccoolcclcclllc:lollc:::::cc:ccccccc:;;;,,,;;;;:cccccccllllllllcclllloooooolllcloollllllccl:;;;;;,;;:cccc:::::;;:    //
//    ;,',,;;;,,;;:clcc::c:::::::::;::::;;ccccccccllllllllccc:cccccc::cccccc:clcclllllolcllllcc:,;::c:;::cc::::;,,'',;;;;;:::::ccccllllcccllllloooccloolllooollolc::;,,,;;:cc::::::;;;::;:    //
//    ,,,;::::::;,;:cccccc:::::;;;;;::::;:clllcccccllcclollcc:cclllcc:cccccc:::cccloololclllc:;:::cc::;;::;;;::,,'''''::;:::::ccccllolcc::lccllllccllolllllooooooolcll:;;;;ccc::;;;;;:::::    //
//    ,,,,;:::::::;,;:ccc:::::ccc;;:::cc::ccccccccclcccccclllccccccccllcccccccc:cc:::cccccccc:::ccc:;;,;:;,,;;;;;;;;;;;:;;;;;:::cclllccc:;:ccclc::clllllllccodooddooddol:::lollcllccccccc:    //
//    ;,,,,;:c:::::,,;::cccc::::::;;;cccccc::ccccllllllccccllc:;::ccccccccccclcc:::;:ccccccllc:c:::;,,,,;,,,;;:;;:::;;,,,,;;;;;;;:cccccc::cccllccclllllllccloooodoooooolllllcloolllllcccll    //
//    ;;c:;::;:c:;;:;,;cllcccc:;::;;:c:;;::::loolloolllc:::::::;,;:ccccclccccccc:;;:ccc:::cc:::;;;:,','',,',,;::;;;,,,,;;,,,;;:;;;:ll::cc::cllllooolllllc:clllllooooooooodooooollllllllccc    //
//    cc::cc:::::;:::::ccllc:::::;;ccc:::clccclllll::cccc::::::;:::::cccclc:::::;,;;;;::cc:;;;;;;;;;;:;,,'''',;;,',,,,,;;,,;;;,,,,;:ccloc::ccllllllllllllccllllllllllolcooooooolcloollllcc    //
//    :::cc::cc:c:cc::clcc:cc:::;;;cc:codl;,clllcccc:cccc:::::::cccccccclllc;,;;;,''',;;;;;;,,,;;;;'':c:;,.',''.',,,,,,,;;:;,'''..,clllllcc::clcllccclllclllccllllllloolcllooolccccllllccc    //
//    cccc:;:c:::;;::::cccc::cc:::::cloool;,:llcclccccccllcclllclllolccccclc;,,;;,'',;;;;;;,,,,;;;,'',;::;,''..'',',,,,;,,,,..'''..,:cclc:;;;::::cccclllllccccclcllccloolllllloolcclollcc:    //
//    cc:;;::;:cccc::::cccccllccclllllllcc::ccllllllccllllllooollclllcllc::;,,;;,,,,,;;;;;;;;,',;;;;;:;,,'..'..,,''',,,,'.''''....'''',:::::::;;;;::ccccllllc::ccc::ccccccccccllolloolllc:    //
//    ::;;:::clccllcc::ccllol::clllllclllllddlloollc:clloolllllllcclllllc;;;'',,,,,,,,,,;::;;,',,;:c:;;,,...,,,,'.''''.''..........',,,::;;::::;,,;;;:::ccclc:;:cc:::::::c:::ccclllllllll:    //
//    ;;;:;;:clccc::c:;:cllll::cllccllol:loolcclllllccllllclllloolcccc::;,,,,,,;;;;;,,,',;;;;,,,,,,,,;;;;;;,,'..'..''...............,;::cc:;;,;;,,,,;::::::ccc::ccc::cccclllclllllllooool:    //
//    ccc:;;:clcllc::::ccccloolooddooc,clodc:llllclolcclllcccclllllcc:,,::::;,;;;,,,,,''',,,;;,,,'''',,,,;;''...''....... ........';:c::::;;,,,,,,,,,;;:::::ccc:::ccclllloooloooooolooooll    //
//    :::::,,;cllc::::cllllllcllooolol::cllcclolllllllccllll:clllcclc:c:;;;:;;;;;;;,,;,'',,'''....'..'''','''..,'.............,;''',;:;,,::;,,,'',;,,;;;::cc:::clcccllcclooooooolloooollcc    //
//    ::;::;;:::;,:::cccclolccc:ccc:cllccccllllllolclllcclllc:ccccccc::;,;,;;,,;;;:;;;,,...'''.''''''.',;;,,,,,;,.....'.';,',,;:c:;;::;;;::;',,'',;;;;;;:::ccc::cccccllc:cclllooddoccllcll    //
//    ccllllccccc;:::clccllcccccccccccccccllccllcclllcclcclcc:::;;;;;:;,''......'';;;;,'...',,;;;;;;;,,'',,,;:::,,,,,,'',;,,:::c:,'',;;::;,,;,;;;::;,,,;::c::clllccclclllcccclloddollllclo    //
//    :;coolllclolccccc:clllcc::ccc::cccc:ccc:ccccccc::cccc:,;c:;,,,;;;;;,,''....',;,'',,',;;;;:::;:c:;;;;;,;;;;,,::cc::c:;;;,,,'.'''',,;:::;,;::cc:,,;;:::cclollc:clccllllooccllllloolccl    //
//    c:clllllclolllcc::cllcc::c:::cc:::cccc:::ccc::::cllc::::::;:;;c:::;;;;'..''',;,';::::cc:::;::c::;;::;;;,;;;:cccclc:clccclcc;;,',;;;:::,,,:cc:;,;;;:cccclllccccllccllloolccclllloolll    //
//    cccllolclc:lolcclllll:,,,;:::cccc::cc:::ccc:::cclll::cccllcccccc:::::;;,'''''',;::::;;:::::c:;:;;::,,;;;;;;:::ccc::c:::ccllcccc:::::cccc::::;;;;;:ccccccc:ccccllllllllolccclollooclo    //
//    llcclc:ccc:cc::cloc;,,,,,,;;:::::;;;;;:cc:::::ccc:::clc::cccccc::::;::;,,''.',;;,,;:;,;;;;;;;;;::;,,;;;:;;;;;;::::::;;:cccclclllc:::cccclc:;,,,,;:::cclc::ccccllclllloollllllccllcll    //
//    lllccc:cc::::::::;'..,::cc::::;:c:;;:::::cccccccccccccc::::ccc:,,;,,;;',,''',;;,,,,,;;,,;:;;,;;;;,,;,,,,;;;;;;;;;:;;;;:cccllllllcc:::;;:cc;;;;;::cccccc:clllllcclcllooollllllc:ccccc    //
//    llcc::::;;;;;:;;,,,;:cccllc::ccccc;:::::;;::::cll::ccclol:ccc::;;:;;;,',,',,,,'',,,,,,;,;;;;,,''''..',;,,,,',;;;,;;;;;;:ccclcccc::;;::::;'';:ccccccc::;;cc:clcccccclllolccllllclllcc    //
//    cc::::;;::cc:::;;;colccc::cclcccccc:;;;:;;;;::cccccccccccc::::::;;;,,,''''.'',,,;;:;;,,,,;;,,''''...',,''.'',,,,,,,,,,;;:cccccc:::::clc;,',;:::ccccc::cc:c::c::clllllccllccccllclccc    //
//    ccccllccccc::::c::llcclc::cllcccccc:,;:::::::cccccc:::::c:,',;::::;;,'..'''',,,;;;;,,,,,,;;,',,,'.',;;,,'.',;;,,,,,;,';;:ccccccc::::::;;;;:;:c;:cccc::cc:cclc:::cllllccllccclllc:ccc    //
//    ccllllccc:cc:::ccc:::cc:c:cccccccccc:cccc;;:::::;;::;;:lc;'..',;;;;,''''',,'',,;;,''',,;,,,;,,,,,,;:;;,;;;;;;;;,;;;;,,,::::cc:::;;;;;,,::;;,;:::cccc::cccoolcclccllllllllccccloc:ccc    //
//    lllllclccc:::ccccccccccccc:::::::::cc:cccc:clccc:::cc::c:;;;,,,;;;:;,,,,,,''''',,,'...','''''''''',,,,;;;;;;,,,,,,;;;;,;:;;::::;;,,;;;;;;:::::cccccc::cccc::clllcclllllllccllloc:ccc    //
//    clllllc:::::::c:::cccllllc::::c:cc:clcllcccccclcccccc:;;;;;;;;;,','''',,,''''...''''................''',,,,,'',,'',;;,'',;;:;;;;;,',;:c:::ccc:::::cc::c::::ccccc::clllllc:cllooc:ccl    //
//    llllllccc::::::::cllllcccc:::cc:::cllcccccccclllccc::;,,;;;;,''......'''.......''....................',,,,,,,'',,,;;,'.'';:;;;;'...,;:c::cc:cc:::clcccccccccccc:::clollccccclolcccll    //
//    lllllllc::c:::;:llllllc::cccc::;:ccccccc:c::cclc:::;;;;,,''''.........................................'',,'....,;,,,,,'''',;:;,'.';::clll:;;cccclcc::ccccllccc:::ccllllclllcllllllll    //
//    ooollc;'..';:::cccclllcccccc:::::cccccc:cc::c:::::;,;;,'''.''..................................''...',,'',,'',;;,''',,''',,;:;;;,';::cllccccccclccc::clclllc:;:::cclccloolccccllloll    //
//    olllc,..'',;clccclllccllllc:::cccccccc;:ccc::::::;,','''''''.............................''..'''''''..''',;,,;;,,'''',,,'';;;:::::;,;;c::lol::cc:cccllcccccc:ccccc::cloolc::looollll    //
//    ooo:,;;::llc:lolclcclllllc:ccccccclccc:::::cc:;,;;,,,,'''''.....''.....................'..........''',,,'',;,,''..''',''',,,,;;:cc;',,;cllcc:cccc:cclccllllcccccc:;:cllccc:cllloollc    //
//    lcc:cl::ccc::coollllcllllccclcccccccllc:;ccc:;,,,'''''''''..........................................'',,,;;;,''.....'''...'',:;;:;,,;;;::cccllc::cllccclloollccc:;:c:;:clccloooooool    //
//    ccccc::clcclllllllollolclollcccccc:clllccc::;;,,'...''''.............................   ..........'''''',;;,,......''.......,;;,,,;:;;:ccolcc:ccclolllllooollllc::::;;:::ccllloolccl    //
//    ccccc:cloloollllllooollloolclcc:::ccllc::;;:;;,''..'',''...........................................''''',,,''..............'',''',,;:cc:cccccclloolollcllloolll:c:;::::::cllllllcccc    //
//    c::cccclllollooloolllclolllcllllllcllc:;;:,',,,'''''....''''.........................................''''''.....'.......';:;;;;::::;:c:;cc:cllloolcllccllooocc::::clc:clclllllllllll    //
//    ::ccc:clllloddoloolccclllooooooooollcccccc;,,,'''''''....'.......................................''.'''''........'..'',;;;;;:;;;::ccclllc::cllooolllolclllccc:::cllcc:cllllooddooool    //
//    ::ccc:ccccllllllllclllllollllloolcccccc::c:;,','''''..............................................,'.','.'''.......';;;;:;''';c;;ccllloolclllllllclollc:ccllccccclccc::clllooollllll    //
//    cc::::ccccclcclllolclooolcc:cclc::cc:cl;;;;;,,,'''''''............................................''.''''''''..'',,;;:::c:;;;;::ccccccllllollllclc;:ccc::llllcccl::cccc:clllllllccll    //
//    c:::;;:cccclcccloooooolllc::cc::::cccll:,,;;,,,','''''.............................................''.'''..',;;;;;;,,;;:c::;;:::::cccccllllcccllcc;;cllllllolccclc:clccccccccccccccl    //
//    c:::;;:cccc::cclollloollllccl:;clllooool;,;;;,'''''''''.........................................''','',;;,,,;;;;;,;;,',:::;;;::::::ccllllc::cccccllc::lolclolc:cclclc::ccc::cccccccc    //
//    c::::::ccccccllllclloooo:;:ccccc:c::cccc:,,;,'''''''''''........''''''.........................',,,,;;;;;;;;:::;;,'',,,,;:,;:::;;;:clllollllcccclcclllllclollcclllcccc:::::::clcccll    //
//    cc::;::ccllccccccllloooo:;ccccccclllccc:::,,'''',''''''''........''.........................'..,,,;;;;:c:::ccc:;;;'.;:;;;;,::;:::::clooolllccccccccllllclllllc::ccccc::c:::::ccccc:c    //
//    c:::;;:::ccc::cclllllllccclc::lllloolllclc;,,''''''',''''........................''''''...''''',,,;:::cc:::cccc:::::ccc;;;,;;;::cccccclolllllc:c:,:lllccllllll:;:c::::::;;:::cccc::c    //
//    cc::;;::cccc:cclllollllcclll:coollllcclllc;;;,,,''.'''''.''...'''...............'',,''''.',,,,,,;;::cllccccccc:;:::clcc:::;;;:cccccclllllcclc:clccllcllclllllllc:::::::;;:ccccccc:cc    //
//    c:;;:;:cccccccccccclc;;::lolclolcclllloolc::;;,,''.''''''''''''''''.........''.''''''''.',;;,',;;,,:c:ccllcc:::::::cc::cc:,;ccccccccllcc:;:cccllc:ccccccoollolccclccccc::clc::::;;;:    //
//    :;,;:;;::cc:::ccclccc::clllolcllcclloollllcc;;;,,,'''''''''''''',,'''''..''''''''''''...',;;;;;;;;;;;;:ccc:c::cccllllccc::;,:c:::::ccccc:;;:clcccc:::cccllcllc:cclccllcc::c:::::;;;:    //
//    ;;:cc::::ccccclooooc;:cllllolcclllllolc:;::::::;;,,,,'',,''''','''''.''''''',''''''...',,;;;;;::::c::cllccccccllllc::clc:::;,:cllllllcclllolllc:cllll::cllclcc::clcccc:::::::::::;::    //
//    :ccc:c::cc::ccloool:;cllllollllc:,'';:c:cc:cc::::;;;,''''',''''''''''''..''''''.'',',,;,;;;;;::cllllcclccllccllollc:clll:'',;:cllcloollooollc:cccccllclcllllllcccc::ccccc:::ccc:;;::    //
//    c;:c:c::::::lloooolc:cooooolloooc,'',:cclllllc:::::,''''',''''''''''''''''''''.',;;;;;;;;:::llllolllc:ccllccccclllollllc;',::coollllllllllllcccllllllllc:clllllc::ccllccc::llcc;;:cc    //
//    lccccc:::::clooolcllccolllllooolcclllclccloolcccllc,.,;,,,,''''''''''''''''',,,;ccc:;;:;:cllllllllcccllooolllccccllclll::c::ccooooooolllolllccllllllcclcccccccllc::::cc:cclccc:;:cc:    //
//    llcccc:::;::::ccclllc:llclllolccclcclllooooolllllllcclc:;;,'',,''',,,,,;;;:::::cllol::ccccccllcccccllllooolllccc:c:::c:::c::clllllllllllllcllllccccc::cclc:;;,;:c:::::::cccc;;:::::c    //
//    clcccc:::::::;:cccc::::clllcccclllllcclooooooooolccccc::cc::::;;;,;::cccccccc:cllc::clcccccc:cclloooooooolcc:::clcc::::ccc:::llloooooooollccccc::ccccccc::;;;,;cccllcc:::;;;::c:;;cc    //
//    cllc::::cccc:::cccc::cllcccllllllllllllllooolloolllccccllccoolcllccc::ccllclllllccc:cc::ccc:cllloolllllllcllc:clccc::::cc:;;:cllloooooooollcllllccc:cllcc::,,:lllllc:::;;;;;::::::cl    //
//    ccccccccccccc:::cc::ccccc:clllllllcllllllloollooollccllc:ccllc:lolllcccclllllollcclllccclllccccclccccclllclllclllcc:::::::::clllcclcclcccccllllccc:;;;;::;::,;:::::;;;;::::;;;;:clll    //
//    c:ccllccccccc:::::;:ccccc::ccllccccccccllolloolllllllolcccclocclllolcclccllllllccccllcccccccccllllllllllccccc:ccccc:::;::::ccc:cccc;;cllllccccccc:c:;;::;;;;;;;;:c::::::;;;;:::ccccc    //
//    c::ccccccc:::c::::::c::ccc:::cccc::ccc::lolloollllcclllc:::cllcclooolllcccclcclllcclooolllcccllooooollllcccc:::;',:;::;;:::::::::c;',clllc:;clc::;;:ccc:;;;;;;;:::;::::;:;,:cc:ccccc    //
//    cc:clc:::;;;:::::;:c::::cccc::cc:;:c::;,;:::cccclccccccc::;:clc:cllcc:::clllllccccllllcclc:ccllccllloolllcccc::;;,;;,,,;:::::::;:::ccccclcc:clc;;;;::::;;::::::::::::::::;,:::cccccc    //
//    cc::clc:::c:::;;;;;::::;;::::;:::;::,,,',::cccllllclcccc:::::::::;;:c:cllllllcc:::::clllolcllol:cllllccccc:::;;;;;;;,;:::;;;;::::cccccoolcc:::::c::::cc:;;;:ccc::cccc:cc::cccccllccl    //
//    lllccllcllllcccc:;:::c:;;::::;;;;::,.';:ccccccclllccc:c::c:;;;:::;;:c:ccclllccccc:cloolcclllcllolcllccccc:::;;;,,;;;:::::::::::ccccclllllccccccccc::cccc::ccc;;:cccccccccccccccccccc    //
//    llllcccclllllccc::cc:c:::;::::;;;:::;;:::cccccccccllc::;;:;,;::::;::c::::ccc:cccllccccclllcccllllcclllccc::;;:;,',,,:::ccccccccccccccccclllccccccccc:c:::cc:;:cclllc:ccc::cccccccccc    //
//    cllllllcccllcccc:::c:::;;;:::::;;;;;;;::cclcc:::c:::;;,;;:;;:::c:;;;::;;::::::c:::::clllllcc:ccccccccc:::c:::;;;,;;,,;::c:ccccccccccccccclccccccccccc:ccccllcclcccccc:::cccccccccccc    //
//    llllllllclollcclc:;:::::::::::;;:::;;;,,;;::ccc::::;;;;;;:;,;;:c:;,;;;;;;:::::::;:::clllllcccc::cccc::::::;:::;::::,'',;:cccccccccllllccccccccccccc::ccclclc::ccccccc::cccccclllcccc    //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ACKSTRACT is ERC721Creator {
    constructor() ERC721Creator("ACKSTRACT", "ACKSTRACT") {}
}