// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tiny Familiars Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//     ...........'''''''''''''....      .......'',;:::;;,,,;:ccclllcccccc:::;:::;,,'..,:::cc:;,,,,;;d0KKXXXXNNNNNNNNNNNNNNNNN    //
//    ..........'''''''''''''''...... .........'',;;;;;;,,;;;;:ccccllllllllc:::::;;;,,,;::cccc:;;;::;ckKKXXXXNNNNNNNNNNNNNNNNN    //
//    ...''.'''''''.'''''''''''...............'',,,,''''',;;'',;::::ccclloolccccccccc:::ccccccc::c:c::d0KKXXXXNNNNNNNNNNNNNNNN    //
//    .'........'''''''''''''''...............',,''','''.''..',;,;:::cllllolllllllllc:;;:llllllc:ccccclkKKXXXXNNNNNNNNNNNNNNNN    //
//    ''''.....''',,,,,,,''''''...''.'..'''''';;,,',,,'......',,'',;loddooooooollolc:cclccc:::clcclllllx0KKXXXNNNNNNNNNNNNNNNN    //
//    ,,,,'''',,,,,,,,;,,,,,,''...',:cc:;,''',;,...'''''....'','.',:lodxdddddoollllc:ccc:;;:clcccclllood0KKXXXXNNNNNNNNNNNNNNN    //
//    ,,,',,'',,,,,''',,'',,,,,'.';ldkOkxo:,',;....',,,'''',,,,',;:clodxxxddddool:;,,,;;:cdkOOxlclloooodOKKXXXXNNNNNNNNNNNNNNN    //
//    ,,,''',,,,,;;,''..'',,,,'..,cdkOxxxOkdc,,'...,;,,,,',,,;,,,::cldxxxxxddoc;,'.''';cdkOOOOdcclooddddkKKXXXXXNNNNNNNNNNNNNN    //
//    ''',',,;,;;;;,,,''...','''';cxkxoloxO0Od:''..,;;,,,,,;;;;;:cccldxxxxxo:,......':oxxkkkkxocclddddddkKKXXXXNNNNNNNNNNNNNNN    //
//    ,'',,,;;;::;;,,,'.....'..',;lxxxdddxkO00kl,..',;;;;;;;;;::cccllooddl;'.......;oxxxxxxkxdc:lodxxdddkKKXXXXXNNNNNNNNNNNNNN    //
//    ,,,,,,;;;:::;,''..........,;ldxxdddxxkOO0Od:...,;;;;:::cc:cccllool;........,cdxddddxxxdc:cldxkxdddkKKXXXXXNNNNNNNNNNNNNN    //
//    ,;;;;;;;;;:;,''.....''''''';loddooooddxxkOOxl,..,:::cclllllloodo:........':odddoodddxdl:lolddoxxddkKKXXXXNNNNNNNNNNNNNNN    //
//    ;;;;;::;;;;;,,',,,,,;;;;;,';looolllllloodxkkko;..,clllloodddddo;........;llc:llc::::::,,cooddodxddOKKXXXXXNNNNNNNNNNNNNN    //
//    ::;;:::::;;;;,,,;;;;;:::;'',,,,''',,;:cc::ldkkd:..':llooodxkkd;..'.....,;'...'............,:oodxdx0KXXXXXXNNNNNNNNNNNNNN    //
//    :::;;;::;;;;;;;;;;:::::;;,''..........';'..';lddc'..:oddxkOkd:''''...........................;oxdx0XXXXXXNNNNNNNNNNNNNNN    //
//    :::;,,,;;;;::::;;:::::::;::;,'.........',,....':oc'..cxOOOOo;,,,,'..........................';lddkKXXXXXXNNNNNNNNNNNNNNN    //
//    :::;,''..',;::::::c:::::;:ool:;,'.......',,'....'cc'.'o000k:,;;;,'....''..........''',,,,;:loodod0XXXXXXXNNNNNNNNNNNNNNN    //
//    ;;;;,,,....':ccccccc:::;;:lkkdl:;,''''..',,'......::..,xK0o::::;;,'...,'.............':lodooddookKXXXXXXNNNNNNNNNNNNNNNN    //
//    ;;;;;;;;;;;;:::ccccccc:::;:dOdc;,'''''.............;;..cOOlcllcc:,'..',,''............'cdddodold0XXXXXXXNNNNNNNNNNNNNNNN    //
//    .',;;;,,;:::;,,;ccccclccc:;::,'''''','..............,'.,oo:;::;,,,''.,;,,''''''',,''....;dxdo:lOXXXXXXXNNNNNNNNNNNNNNNNN    //
//    ...',;:,.';;,'',;:cccclllc;,'''''',:llc;''..........''......... ......,,,,,,,,,,,,'''....;clclOXXXXXXXXNNNNNNNNNNNNNNNNN    //
//    ;'.',;::,',;;;;;;::cclllc:,,,,,,,,;:codol:;,'''''''....''.............'''',;;;;;;,,,,,,'..,:lOXXXXXXXXNNNNNNNNNNNNNNNNNN    //
//    xc:;;cccccclcc::;::cllllc:::::;;;;;;::ldxdoc::;,''..';;;,,,'..........',,'.;cllc:;;;;::;;,;oOXXXXXXXXNNNNNNNNNNNNNNNNNNN    //
//    0kdlllllloddoc:::::cloooodddollodolllllodxxxdocc:::;;,,,,,,,'.............:xO0K0d:codooc;:d0XXXXXXXNNNNNNNNNNNNNNNNNNNNN    //
//    K0OxdoooodxxxdlcccloooodxkkkdoloxO00kdooodxkkOOKKKK0kd:'..................lOkxOKO:;xOxl:cxKXXXXXXNNNNNNNNNNNNNNNNNNNNNNN    //
//    KK00kdooodxxkxxdlllodxxxkOO0Okxl:cdkd:;;::oOKXNN0kxxkOko,.................lkl,:k0l'lxlclOXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNN    //
//    KKKK0OdoooodxkkkddddxkO0K0KK00KOd:;::;:codkKXNX0l;::cokOl'................lOo;,d0d;cllxKXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    XXKKKK0kocclddxkOOOkkO0KKKKKKKXXKOdl::coxk0KXXX0xl:::lOXk:''''',,,'''''...:OXOOKKxookKXNXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    XXXXKKK00koc:codxkO000KKKKKKXXXXXXK0kocclok0KXXXXKOOOKXNKl,,,,,;;,,;,,'''.,xXXXX0kk0XNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    XXXXXXKKKK0koclllodxk000KKKXXXXXXXXXKK0OxooxOXXXNNNNNXXX0l,,,,:llccclc:;,'.c0XKKOkKNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXX    //
//    XXXXXXXXKKKK0OkdollccldkO0KKKKXXKKKKKKKKxlc:dKXXXNXXXXKKk:,;;;:odooxxdc:,'''lkO0x;oXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXXXXX    //
//    XXXXXXXXXXKKKK00OkxolccldkO00KKKKKXKKKKklcc:ckKXXXXKK00Oo;,;;;:cllodolc;;,'',lkxc.,ONNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXXXXX    //
//    NNXXXXXXXXXXKKKKK00OkxxxxkOOOO000KKKKK0dlc:;;cdk00000Oxl:;;;;;:::ccc:::;;;;;,,:;..,kNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXXXXXXX    //
//    NNNNXXXXXXXXXXXKKKK0000OkkkxxkOO00KKKKOolc:;;;;:clolllc::::::::::::::::::::::;,'.'oXNNNNNNNNNNNNNNNNNNNNNNNNNNXXXXXXXXXX    //
//    NNNNNNNNXXXXXXXXXXKKKKK0000OOkkkkkkkOOxloolc:;;;;;;::cllllllllllllllccllllllcc::,:kNNNNNNNNNNNNNNNNNNNNNNNNNXXXXXXXXXXXX    //
//    NNNNNNNNNNXXXXXXXXXXKKKKKKKKKKK000OOOd;,cdddolllloooodddddddooooooooooollllllccc;',dXNNNNNNNNNNNNNNNNNXXNNNXXXXXXXXXXXXX    //
//    NNNNNNNNNNNXXXXXXXXXXXXXKKKKKKKKKKKX0c',,:ldxxdddxxxxxxxddddddddddddddoooollccc:,'.'dXNNNNNNNNNNNNNNNNXXXNXXXXXXXXXXXXXX    //
//    NNNNNNNNNNNXXXXXXXXXXXXXXXXXXXXXXXXX0l',;;:clc;;:cclloodxxdddoooolllcccc:;;,,''''''.'lKNNNNNNNNNNNNNNNNNNXXXXXXXXXXXXXXX    //
//    XNNNNNNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXkc:ccc:,,,,,,,,,,;:cc:;;,,,,,,,,'''''''.''...'''c0NNNNNNNNNNNNNNNNNXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKkl:lo;;cccclc:;,,,,,;::;,,'',,,'',,'''''''''.',,,''.,lONNNNNNNNNNNNNNXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXO:.  ....'',:llolc::cll:;,,,;;,,,',,,'''''',;,',,;,......:OXNNNNNNNNNXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXd' .....'',,'',:loodxxdl::c::;;,,,;;;,,,,,,,;cc;,'........ .:kXNNNNNNNXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXKxoxkOOo. ....'',,;;;;;,,,;:odollcc:::::cccc:::;;::codl;'..,,'...... .:OXNNNNXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXk'..........'''',,,;;;::::;;,;:clooooooooolllccccloxOxoc;'.,;,''.....  .lKNXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXX0:.......'''''''',,,,;;::cccc:;;:dkkkkxxxddddoddoooodxxdl:,,,;clcc:;,''..;OXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXk;.....'''''''''''',,,;;:clol:;:lddoolllllccc::;;,,,:ldddooc:::::;;;;;:;;dXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXKkc,,,'''''..'''',,;;:cclodoc::cl:,,,,,''''''''''''''',;::cc;...........'lOKXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXKklcllllcccccccllooddxxkkkocloooc,'''''''''''''''''........................;oOXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXOo:'',;clodddddddddddooollllooddoc,'''''''''''''''.............................'ckXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXX0xc'...''',,;;;;;;;;,,,,,,,,,,,;;:;,'''...'''''''''''...............................'cOXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXX0o;.......'''''''''''''''..'''''''''''''''''''''''''''................................'.,dKXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXKkc'..........''''''''''''......'''...'''''''''''''''.......................''...........''''o0XXXXXXXXXXXX    //
//    XXXXXXXXXXXKx:..................'''''''''''''''''''''''''''''''.........................'''.......'''''''''l0XXXXXXXXXXX    //
//    XXXXXXXXXXOc,''...................''''''''''''''''''..'''''............................'''''......''''''''''cOXXXXXXXXXX    //
//    XXXXXXXXKx:::cc:;'.................'''''''''''''''''.'''''.................'..........''''''''....''''''''''.:OXXXXXXXXX    //
//    XXXXXXXKxcccclllcc:;,''..'''''''''''''''''''''''''''''''''''',,,,,,,,,,,,',''''''''''''''''''''''''''''',,''''c0XXXXXXXX    //
//    XXXXXXXklccccllllllllcc:;;;,,,,,,,''''''''''',,,,;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,'''''''''''''''''''''',,,,,''lKXXXXXXX    //
//    XXXXXXKdccccclllllllllllllc:::;;;;;;,,,,,,,;;;::cccc:::;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,'''''''','''''',,'',,,,,,';kXXXXXXX    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TFE is ERC1155Creator {
    constructor() ERC1155Creator() {}
}