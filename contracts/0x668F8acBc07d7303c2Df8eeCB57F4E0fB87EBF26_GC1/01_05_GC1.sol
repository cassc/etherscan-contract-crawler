// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gone Crazy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    lllllllllllllllllllllooooooooooooooooooooollllllllllllllllllllllloooooooooooooooddddddddddddddddoooooooooooooollllllllll    //
//    lllllllllllllllllllllooooooooooooooooooooollllllllllllllllllllllloooooooooooooooddddddddddddddddddoooooooooooollllllllll    //
//    lllllllllllllllllllllllooooooooooooooooooooooollllllllllllllllllloooooooooooooooooddddddddddddddddoooooooooooollllllllll    //
//    lllllllllllllllllllllllllllllllloooooooooooooolllllllllllloooooooooooooooooooooooooooddddddddddddoooooooooooooolllllllll    //
//    lllllllllllllllccccllllllllllllllloooooooooooollllllllllllolc;;cloooooooooodoooooooddl;;ldodddoodoooooooooooooolllllllll    //
//    lllllllllllllllccccccclllllllllllloooollllloollllllloooooloolc;:::oodxkkkOkxxxxdddxxl;';ldooodoooooooooooooooooollllllll    //
//    llllllllllllllcccccccccccllllllllllllllllllllllloooooooooooooc;:c;:odxkOkxxddolllooc;,':ooooooooooooooooooooooooolllllll    //
//    lllllllllllllcccccccccccccclllllllllllllllllllllooooooooooooool:::cooddddollol:::;,,'';loooooooooooooooooooooooooollllll    //
//    llllllllllllcccccccccccccccclllllllllllllllllllllooooooooloolodolloooooooolool::c:;'';odooooooooooooooooooooooooooolllll    //
//    llllllllllllccccccccccccccccclllllllllllllllllllllooolllooooloxdlxOxcclcclccccc;,::'.:dooooooooooooooooooooooooooooollll    //
//    ccccllllllllllllllccccccccccccclllllllllllllllllllllllllllooloxxo:;lolllllccc::,,,..,looooooooooooooooooooooooooooooooll    //
//    cccccccclllllllllllllllllccccllllllllllllllllllllllllllooooooodOk,'cdxdolllcc::;,. .cdoooooooooooooooooooooooooooooooool    //
//    ccccccccclllllllllllllllllllllllllllllllllllllllllllllolooooookK0OkOOkdodoc:::;:;,''cdoooooooooooooooooooooooooooooooool    //
//    ccccccccccclllllllllllllllllllllllllllllllllllllllloooooooodxkKKOOOOxoodxo:::,',,,,',ldooooolloollooooooooooooooooooooll    //
//    :ccccccccccclllllllllllllllllllllllllllllllllllllloooooooodOKKKOOOkoloxkxc,::;,'.','':oddooooooollloooooooooooooooooolll    //
//    :::cccccccccccllllllllllllllllllllllllllllllllllloolooooldKXKK0kkxdloxkdc,''',,...''',::odoollllllllooooooooooooooooooll    //
//    :::cccccccccccclllllllllllllllllllllllllllllllllllollloooOXK0Oxxdocoxkkd;....,,'..''',,;:coollllllllllllllooooooooooooll    //
//    ::::ccccccccccllllllllllllllllllllllllllllllllllllllooookK0Okkxddooddxxo:..';;;;;,,,,',;;;coooolllllllllllllooooooolllll    //
//    ::::ccccccccccllllllllllllllllllllllllllllllllllllllloxOKKOOkkxoloolloolc;,;:::;:;;,,'';;;codoolllllllllllllllllllllllll    //
//    cccccccccccccllllllllllllllllllllllllllllllllllllllodOKXXKOOkxddxdc:clccc:::;;;;;;,,,',::::cxxdollllllllllllllllllllllll    //
//    ccccccccccccllllllllllllllllllllllllllllllllllllllox0XXXK0Okkxdool::lllcccc:::;;;;,,;;,,;:;;lxkxolllllllllllllllllllllll    //
//    ccccccccccccllllllllllllllllllllllllllllllllllllookKNNNNK0Okkkxxxdloddolcclcc:::;;;;,,;;:ccccdOkdlllllllllllllllllllllll    //
//    ccccccccccccclllllllllllllllllllllllllllllllllllox0XXXNX000OOOkxddxxxdollclcc:;:;,;;,:::;:ccclxkxlllllllllcclllcllcccccc    //
//    cccccccccccccllllllllllllllllllllllllllllllllllodOXXKXK0OOkddoccoooooolcc:;;,;;;;;,,',;;,;:c::lxxolccccccccccccccccccccc    //
//    ccccccccccccclllllllllllllllllllloddlloodoooooooxOKKKK0kxdoocccldolloooc::;;:llc:::;,,;;,',:::ldollccccccccccccccccccccc    //
//    ccccccccccccllllllllllllllllllooooxOkxddkkxxxdddxOKKK0Oxdoolclcclllcloolllcccclc:;;;;;,;;',:ccddlccccccccccccccccccccccc    //
//    cccccccccccllllllllllllllllodxxddxxkOkdodxxxkkOkOK0OOOOxdollcc:::::::::ccccc:;,;;;;,,',,,,,;lxkxlccccccccccccccccccccccc    //
//    cccccccccclllllllllllodxkkkxkOOOkxxxxdllododdoxkk0XKOkkxdoolcc:c::;,,;::cc:::;,'';;,''''',;lxkdolccccccccccccccccccccccc    //
//    cccccccccclllllllllllldOKNNXK0Okkxdxxdlldkkdddddx0XOxxxxxoolclllcc:::::;;;;,,',;;:;;;;;:coxkkdlccccccccccccccccccccccccc    //
//    ccccccccclllllllllloxk0KKXXXK0OkxxdddddodddodxxxOXKxololc::::cllllccccc:;;;;,,:cclccccccokOkdlcccccccccccccccccccccccccc    //
//    cccccccccclllllllldk0XNNNXXK0kkkxxdddoooooolclk0XKOxdoc:::::clllodolloolccc:::cllllccllldOOxdlcccccccccccccccccccccccc::    //
//    ccccccccccllllllok0KXNNNXXXXKkoloolloocclcc::oOXX0kkxl::cllool:ldxxxdddoollcccloolllclooxkkdlccccccccccccccccccccccccc::    //
//    cccccccccclllllokKXNWWNK0KKXX0xlcl:;:cc::c::d0XK0Okxxdllllccc:codddxxddddollllooolccccloxxxdlccccccccccccccccccccccc::::    //
//    cccccccccclllldx0XNNNNXKKKKKK0kdoll:;cc:;:cdKXK0O00kxdddddlloolllloddodddoollloolcccccldxdollcccccccccccccccccccccc:::::    //
//    cccccccccccclox0XNNXXK0OkkOKK0kdlccc;::;,:o0XKK000Oxdooollolllloddxxolooddoooodollllllldxxolccccccccccccccccccccccc:::::    //
//    cccccccccccclox0KXXKKOkkxddxOOxo:;;:;;;'':kXK000Okkxddoooddddkkxxxdoldxxxxxxdxxdollllloddolcccccccc::::::cccccc:ccc:::::    //
//    ccccccccccccldkKXNXX0OOxocccdxol:,;;;,,';dKX0OOkxxkxkkxxxdxkkkkkkkxdlclllodxdddolccclldxdllcccccccc:::ccccccccccccccc:::    //
//    ccccccccccccox0NWNXKOxdoc:::lddc::;;;,,,lOXXOkOOkkkkkxxkxdxkkkkkkkxkkxxddddddooolcccclxxollcccccccc::ccccccccccccccccc::    //
//    ccccccccccclokKNNX0OkxkkkdodxOOoc:::,,,;oKXKOOOO0OkOkxxdddddddxkkkxxxxxkkkOOkxxddollcoxxocccccccccc:cccccccccccccccccccc    //
//    cccccccccclld0XNX0kxdxxkkxxkO0Oxolc;,,,:kKK0OO0000kkkddolooodddxkkkxxoddoodxdolcccccloxxoccccccccccccccccccccccccccccccc    //
//    cccccccllclokKNNKkoccllc:::;:codllc;;,,cOK00KKXKOkxdollooooooooxxddxxxddddooollccllloxxolccccccccccccccccccccccccccccccc    //
//    ccccccllllldOKNKOxlclccc:;,''',;::c:;;;lOKKKKK0kdxocllolooocccodxddddddoodxxdooolllloxOkoccccccccccccccccccccccccccccccc    //
//    ccccccllllodk0K0kdc::llc::;;;::c:;::;,;d0KKKK0xoooclllllolccclodddxdddolloddddoolc:clox0Oocccccccccccccccccccccccccccccc    //
//    ccccccccclldxO0Oxl:;:ccc:::ccllc:cc:;;ckKKK0Okooolccllclllcccllcoxxdddolllooolcclolccodx0Ooccccccccccccccccccccccccclllc    //
//    cccccccccclox0KOdc;;;:cc:;:clcc:clc;;:oOKK0OkdooolccccccllccclcldddoooolllllolclllooodxxkOxlcccccccccccccccccccccccllccc    //
//    cccccccccclodkOkolc::cllc::cllcooolc:cx00Okxdoolclc::cccllcccclloolooolcccllllccooodddxxxkdlccccccccccccllllllllllllllll    //
//    cccccccccccodkkxolc:ccllc::ccclxxl:;:okOOOxdoooc:cc::ccccc:cccclolllllcccclllloooddxdddxxxolccccccccccllllllllllllllllll    //
//    cccccccccclddxkkxl::cclllcccccdkxl;,;okOOkdollcc:::;::::ccc:;:lollcclc:ccclcloodddxxooodxdllccccclllllllllllllllllllllll    //
//    ccccccccccllldkOxolllccllllllldkdlc:lxxxkxdlc:::::;,;::::c::clllccccc::::clclooodddollldxollllllllllllllllllllllllllllll    //
//    ccccccccccccldxddooolccooollccoxxlcclodddolc:::::,;;;;;::ccclcc:ccc:::::cllllodoloollclddollllllllllllllloolllllllllllll    //
//    cccccccccccllloddddollcclcllccllolllloodol:;:;::,'',;;:cc:::;:::::;;;::cllloodoolllccloolllllllllllllooooooollllllllllll    //
//    ccc::::::::ccccldxxdoollllllcllloddoolllccc;;;;,,',,,;:::;,,,,;;;,,;::;:cclllolcccccloolllllllllllloooooooooolllllllllll    //
//    c:::::::::::ccccodolooodddolc:c:clllollllll:;;;,,',,,;:;'..',,,;:::ll::,,,;:::c::clooolllllllolooooooooooooooollllllllll    //
//    ::::::ccccccccclllodddddooddoodlclooollc:c:,,,''''',,,'.....''';clcclloc'...,,;;:coooloooooooooooooooooooooollllllllllll    //
//    :::::cccccccclllllddodxddodxxxkkxkxxxolc:,......'.''....''''''...',;,,cl;........'''''';looooooooooooooooolllllllllccccc    //
//    ::c::cccccllllllloooddxdddxxkkkOOOkxxxo:;,,'...',''''.'',',,,,''..';;,:c;..''...'''......;looooooooooollllllllllcccccccc    //
//    :c:::cccclllllloooooddddxddxxxxkkOkxl:;,,,,,',,,,,',,,,,,,,,,,,''''...;:;''''''',,,''.....';lllllllloolllllllllllcclcccl    //
//    ::cc:::::ccccclllllllloloxxoccccccc:,',,,,,,,,,,,;,,,,,,,,,,,,,,,,''.''..',,,,,,,,,,,,'''...,;;,,'',;,;c:;,,;;;;:;,;;;;,    //
//    ',;,''.',',,,'','',,,,;,:dxc.',,,;;;;,,,,,,,,,;,,,,,,,,,,,,,,,,,'',,,,'',,,,,,,,,,,,,,'','''',;;;,'..'';;','''''''.'''''    //
//    .,,''..''',,''''',,,'',,;dx:'',::;,;;;;;;,;,,,,,,,,,,,,,,,,,,'''''',,,,,,,,,,,,,,,,,,,'',''',,,,,,'...';;,,''''''''''..'    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GC1 is ERC721Creator {
    constructor() ERC721Creator("Gone Crazy", "GC1") {}
}