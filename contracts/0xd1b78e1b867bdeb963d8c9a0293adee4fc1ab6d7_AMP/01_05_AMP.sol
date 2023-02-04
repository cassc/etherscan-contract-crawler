// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AlfonzoMusicPhoto
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    ccccccllllllllllllloooooooooddddddddddxxxxxxxxxxxkkkkkkkkkkkOx;..'cxkkOOOOkxdolloc;;,:l:,,;,;codkO000000000000000000000O000OOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkxxxxxxxxxxxdddddddoooooooooollllllllllllcccc    //
//    :::cccccccccccclllllllllllooooooooodddddddddxxxxxxxxxxkkkkkkko'..'cocldxdl:;'...................,:codxkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkxxxxxxxxxxddddddddddoooooooollllllllllccccccccccccc:    //
//    ::::cccccccccccclllllllllloooooooooddddddddddxxxxxxxxxxkkkkxxc'...',,;::,'..........................'';;cdkOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkxxxxxxxxxxddddddddddoooooooollllllllllcccccccccccc::::    //
//    :::ccccccccccccllllllllllloooooooooddddddddxxxxxxxxxxxkkkkxdd:...,::;;,..................................';ldkOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkxxxxxxxxxxddddddddddoooooooolllllllllllccccccccccc::::    //
//    ::cccccccccccclllllllllllooooooooodddddddxxxxxxxxxxxxkkkkkxxd;...;c:,''.....................................';lxOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkxxxxxxxxxxxddddddddooooooooolllllllllllccccccccccc::::    //
//    :cccccccccccclllllllllllooooooooodddddddxxxxxxxxxxxxkkkkkkkko,.',,,,''........................................':oxOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkxxxxxxxxxxxdddddddddooooooooolllllllllllccccccccccccc::    //
//    cccccccccccllllllllllllooooooooddddddddxxxxxxxxxxxxkkkkkkkdl:,,,,,''......................................'.....':dkOOOOOOOOOOOOOkkkkkkkkkkkkkkkxxxxxxxxxxxxdddddddddooooooooollllllllllllcccccccccccc::    //
//    ccccccccccllllllllllloooooooodddddddddxxxxxxxxxxxxkkkkkkkxoc;,,,''.........................................''....':dOOOOOOOOOkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxddddddddddooooooooollllllllllllcccccccccccc::    //
//    ccccccccllllllllllllooooooooodddddddddxxxxxxxxxxxxkkkkkkkxdl;,''.............................'''.............''''.';lxOOOOOOOOOOkkkkkkkkkkkkkkxxxxxxxxxxxxddddddddddoooooooooollllllllllllcccccccccccc::    //
//    ccccccccllllllllllloooooooooddddddddddxxxxxxxxxxxxkkkkkkkkd:''...............................................''''''.'cxOOOOOOOOOkkkkkkkkkkkkkkxxxxxxxxxxxdddddddddddoooooooooollllllllllllcccccccccccc::    //
//    cccccccllllllllllloooooooooddddddddddxxxxxxxxxxxxkkkkkkkkx:''...................................................''''.,lkkOOOOOOOkkkkkkkkkkkkkxxxxxxxxxxxddddddddddddoooooooooolllllllllllllcccccccccccc:    //
//    cccccllllllllllllloooooooooddddddddddxxxxxxxxxxxxkkkkkkkd:....................................................'''''''.':dkkOOkOOkkkkkkkkkkkkkxxxxxxxxxxxdddddddddddooooooooooollllllllllllllcccccccccccc    //
//    ccccllllllllllllloooooooooddddddddddxxxxxxxxxxxxkkkkkkkd:......................................................''''''...;okOkkOkkkkkkkkkkkkkkxxxxxxxxxxxdddddddddddooooooooooolllllllllllllllccccccccccc    //
//    cccclllllllllllllooooooooddddddddddxxxxxxxxxxxxkkkkkkkd;.......................................................'''''.....;dkkOkkkkkkkkkkkkkkkxxxxxxxxxxxdddddddddddooooooooooolllllllllllllllccccccccccc    //
//    cclllllllllllllloooooooooddddddddddxxxxxxxxxxxxkkkkkkx:..........................................................'''......;dkkkkkkkkkkkkkkkkxxxxxxxxxxxxdddddddddddooooooooooollllllllllllllllcccccccccc    //
//    llllllllllllllooooooooooodddddddddxxxxxxxxxxxxkkkkkkxc...........................................................'''.......:xkkkkkkkkkkkkkkkxxxxxxxxxxxxdddddddddddooooooooooollllllllllllllllcccccccccc    //
//    llllllllllllllooooooooooddddddddddxxxxxxxxxxxxkkkkkko'.............................................................''......'ckkkkkkkkkkkkkkkxxxxxxxxxxxddddddddddddooooooooooollllllllllllllllcccccccccc    //
//    llllllllllllloooooooooooddddddddxxxxxxxxxxxxxxkkkkkx:...............................................................'.......,dkkkkkkkkkkkkkkxxxxxxxxxxxddddddddddddooooooooooolllllllllllllllllccccccccc    //
//    lllllllllllloooooooooooodddddddxxxxxxxxxxxxxxkkkkkkd,...............................................................''.......cxkkkkkkkkkkkkkxxxxxxxxxxxddddddddddddoooooooooooolllllllllllllllllcccccccc    //
//    lllllllllllloooooooooooddddddddxxxxxxxxxxxxxkkkkkkkl'...............................................................''.......,okkkkkkkkkkkkkxxxxxxxxxxxxddddddddddddooooooooooolllllllllllllllllcccccccc    //
//    lllllllllllooooooooooddddddddddxxxxxxxxxxxxxkkkkkkx:.................................................................''.......ckkkkkkkkkkkkkxxxxxxxxxxxxxddddddddddddoooooooooollllllllllllllllllccccccc    //
//    llllllllllooooooooooddddddddddxxxxxxxxxxxxxkkkkkkkx;.................................................................'''......:xkkkkkkkkkkkkkxxxxxxxxxxxxddddddddddddooooooooooolllllllllllllllllccccccc    //
//    llllllllooooooooooodddddddddddxxxxxxxxxxxxxkkkkkkkx;..................................................................''......ckkkkkkkkkkkkkkxxxxxxxxxxxxxdddddddddddooooooooooollllllllllllllllllcccccc    //
//    lllllllloooooooooooddddddddddxxxxxxxxxxxxxkkkkkkkkd;..................................................................'''.....lkkkkkkkkkkkkkkkxxxxxxxxxxxxdddddddddddoooooooooooolllllllllllllllllcccccc    //
//    lllllllloooooooooooddddddddddxxxxxxxxxxxxxkkkkkkkkxc'.................................................................'''....'lkkkkkkkkkkkkkkkxxxxxxxxxxxxxdddddddddddoooooooooooolllllllllllllllllccccc    //
//    llllllloooooooooooddddddddddxxxxxxxxxxxxkkkkkkkkkkxc'..................................................................'''...,dOkkkkkkkkkkkkkkkxxxxxxxxxxxxxdddddddddddoooooooooooolllllllllllllllllcccc    //
//    lllllooooooooooooddddddddddxxxxxxxxxxxxkkkkkkkkkkko,...................................................................'''...,dOOOOkkkkkkkkkkkkkkxxxxxxxxxxxxdddddddddddooooooooooooolllllllllllllllllcc    //
//    llllooooooooooodddddddddddxxxxxxxxxxxxxkkkkkkkkkdc;'..................................................................'''''..'lkOOOOkkkkkkkkkkkkkkkxxxxxxxxxxxdddddddddddoooooooooooolllllllllllllllllll    //
//    llloooooooooooddddddddddxxxxxxxxxxxxxxkkkkkkkkko'..................................................................'..'''''...':okOOkkkkkkkkkkkkkkkkxxxxxxxxxxddddddddddddooooooooooooooolllllllllllllll    //
//    lloooooooooooddddddddddxxxxxxxxxxxxxkkkkkkkkkkkc......................................................................'''''.....'lkOOOkkkkkkkkkkkkkkkxxxxxxxxxxxdddddddddddooooooooooooollllllllllllllll    //
//    oooooooooooddddddddddddxxxxxxxxxxxxkkkkkkkkkkOx;......................................................................'''''......,dOOOkOkkkkkkkkkkkkkkxxxxxxxxxxxddddddddddddooooooooooollllllllllllllll    //
//    ooooooooodddddddddddxxxxxxxxxxxxxkkkkkkkkkkkkOo'......................................................................''''.......'lOOkOOkkkkkkkkkkkkkkkkxxxxxxxxxxddddddddddddooooooooooolllllllllllllll    //
//    ccclloooooooooddddddxxxxxxxxxxxkkkkkkkkkkkkkkOo'..................................................................................;xOOOOOOkkkkkkkkkkkkkkkxxxxxxxxxxxdddddddddddooooooooooollllllllllllll    //
//    '',;;;;;::::::codddxxxxxxxxxxkkkkkkkkkkkkkOOOOo'..................................................................................'oOOOOOOOkkkkkkkkkkkkkkxxxxxxxxxxxxddddddddddddooooooooooollllllllllll    //
//    '',;;;;;;;;;;;;:odxxxxxxxxxxkkkkkkkkkkkkkkOOOx:.................................................................................'..lOOOOOOOOOkkkkkkkkkkkkkxxxxxxxxxxxxddddddddddddooooooooooolllllllllll    //
//    '',;,'',;:;;::;;:ldxxxxxxxkkkkkkkkkkkkkkOOkOOx:...................................................................................,dOOOOOOOOOOkkkkkkkkkkkkkxxxxxxxxxxxxxdddddddddddooooooooooollllllllll    //
//    .'','..',:;,,;:;;:cdxxxxxkkkkkkkkkkkkkOOOOOOOx;..................................................................................,oOOOOOOOOOOOOOkkkkkkkkkkkkkxxxxxxxxxxxxdddddddddddoooooooooooollllllll    //
//    ........';,'.';:::;coxxkkkkkkkkkkkkkOOOOOOOOOd,................................................................................'':k0OOOOOOOOOOOOOkkkkkkkkkkkkkxxxxxxxxxxxxdddddddddddoooooooooooolllllll    //
//    '.......','...';:::;:oxkkkkkkkkkkkOOOOOOOOOOOd,................................................................................''lO0OOOOOOOOOOOOOOOkkkkkkkkkkkkkxxxxxxxxxxxddddddddddoooooooooooolllllll    //
//    .......'..''''';:;;;::lxkkkkkkkkkOOOOOOOOOOOOo'...............................................................................'';d00OOOOOOOOOOOOOOOOkkkkkkkkkkkkkkxxxxxxxxxxddddddddddooooooooooooolllll    //
//    ...''..'.'',;,',;'',::cdkkkkkkOOOOOOOOOOOOOO0kc'..............................................................................''lO00O00OOOOOOOOOOOOOOkkkkkkkkkkkkkkxxxxxxxxxxdddddddddddooooooooooooooll    //
//    ...''..'..',;,''''',;lxkkkkkkOOOOOOOOOOOOOO00OOl'............................................................................',ck0000000OOOOOOOOOOOOOOkkkkkkkkkkkkkxxxxxxxxxxxdddddddddddooooooooooooooo    //
//    ...'''''..,,;,''''',,:dkkkOOOOOOOOOOOOOOO000000k:..........................................................................,oxkO000000000OOOOOOOOOOOOOOOkkkkkkkkkkkkxxxxxxxxxxxddddddddddddooooooooooooo    //
//    ..........'',''',;,,,,cdkkOOOOOOOOOOO00000000000o'........................................................................'o000000000000000OOOOOOOOOOOOOOkkkkkkkkkkkkxxxxxxxxxxxxdddddddddddoooooooooooo    //
//    ........'''',,'',,,,,;coddxxxkkOOOO0000000000000Oc........................................................................:k0000000000000000OOOOOOOOOOOOOOkkkkkkkkkkkkkxxxxxxxxxxxdddddddddddooooooooooo    //
//    ......',,,,,::;,',''';cddool::dO00000000000000000x;.....................................................................':d000000000000000000OOOOOOOOOOOOOkkkkkkkkkkkkkkxxxxxxxxxxxddddddddddddooooooooo    //
//    ..''.'''',,,;;,'',;;;,;:cldo::dO00000000000000000Ol.....................................................................;dO0000000000000000000OOOOOOOOOOOOOkkkkkkkkkkkkkkxxxxxxxxxxxxxdddddddddddddooooo    //
//    .....'''''',;;'''';:cc:;,;::;:d000000000000000K000d;...................................................................,oO000000000000000000000OOOOOOOOOOOOOkkkkkkkkkkkkkkkxxxxxxxxxxxxdddddddddddddoooo    //
//    .....''''''',''''',:::;,',,,;;oO00000000K0000KK00xl;..................................................................,d00000000000000000000000OOOOOOOOOOOOOkkkkkkkkkkkkkkkkxxxxxxxxxxxxddddddddddddddoo    //
//    ......'''.''',,,'',,,,''',,,,:oO0000000K00K0kxxxxdo:'................................................................'l0KKKKK00000000000000000000OOOOOOOOOkkdlcclldkkkkkkkkkkxxxxxxxxxxxxddddddddddddddd    //
//    .......''.'..',,,,''''....''',;dOOkkOOO0K0KOocccclxkl'...............................................................'oKKKKKK00000000000000000000OOOOOOOkxdo;,''.':odxkkkkkkkkxxxxxxxxxxxxxddddddddddddd    //
//    .........''.....''..'','.....',;:;:lollxO0K0xdddddk0x,...............................................................'l0KKKKK00000000000000000000O0OOOOkd:,,'','''.';cdkkkkkkkkxxxxxxxxxxxxxxddddddddddd    //
//    ...'.........'....'''.'''''...''..'''',,;:ldddddddddl'..............................................................''l0KKKKKKK0000000000000000000OOOOOOxo:,,,,,,;;cloxkkkkkkkkkkxxxxxxxxxxxxxdddddddddd    //
//    ...'......................'....''...''',,'':oddddl;,'...............................................................''l0KKKKKKK0000000000000000000O00Okdoc;,;;,',;:clxkkkkkkkkkkkkxxxxxxxxxxxxxddddddddd    //
//    .....................................'',:clodddddolc,...............................................................''c0KKKKKKK000000000000000000000OOo;,,,',''',,';:okkkkkkkkkkkkkkxxxxxxxxxxxxxxxddddd    //
//    .......................................',:looddddolc,...............................................................'.cOKKKKKKK00000000000000000000Odll:,;,,;;',odcoxkOkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxddd    //
//    .........................................',codddool:'...............................................................'.;kKKKKKKKK0000000000000000000Ox:;:;;:cdxl:dOkkkOOkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxd    //
//    ..............'............................,coooool;..................................................................,dKKKKKKKKK0000000000000000000xc::;codxOo:dOOOOOOOOkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxx    //
//    ..........'..,;'...........................':oooooc;,::'..............................................................'ckO0KKKKKKKKK0000000000000000Okd;,:okkOo:dOOOOOOOOOOkkkkkkkkkkkkkkxxxxxxxxxxxxxxx    //
//    .........','................................;lodddoool:'..............................................................',;:ldxkO0000K00K00000000000000OOxoxOOOOxlxOOOOOOOOOOOkkkkkkkkkkkkkkkkxxxxxxxxxxxx    //
//    ..........'....''''.......................',cddooc;,''.................................................................''.'',;clodkOO0K000000000000Oxlccok00O0klx0OOOOOOOOOOkkkkkkkkkkkkkkkkkkkkxxxxxxxx    //
//    .............'''''...................',;:cllc:;''.............................................................................'',,;:lodkOO00K00000Odol::cdO0O0kld0OOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkxxxx    //
//    ..............''.......''.......',;:clllc;,'.......................................................................................''',;:codkkO000Oxoc:clx0000kld0OOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkk    //
//    .................''''''....,;:clllc:;,''.................................................................................................',,;:clodxkkdldxk0O00kld0OOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkk    //
//    .....................,;::cclcc:;,'...........................................................................................................''',,;:cllodxO000kld00000OOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkk    //
//    ...............',;:ccllc:;,''......................................................................................................................''',;:clodxdcd00000OOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkk    //
//    .........',;;:cccc::;,'................................................................................................................................''',,;;;:cloxO000OkkkkkkkxxkkkkkkkkkkOOkOOkkkkkkk    //
//    ...',;;::ccc:;;,,'..........................................................................................................................................''''''',;ccccc:::::::;;;:;;,,;;:clooxkkOkkkk    //
//    :cclllcc::;,,'......................................................................................................................................................''',,,,;;;;;;,.............',cxkkkkk    //
//    odddoollcc:;,'..................................................................................................................................................'''''',,''''''',,''..............'ckkxkx    //
//    loddxxxxxxxddolc;.............................................................................................................................................''',,,,,,,'''''.....''''''..........,ldoll    //
//    ccllodddxxkkkkkkxo:'...........................................................................................................................................'''',,,'''''...........''''''''''''',,...    //
//    ::::clllooodddxxxxxo;..............................................................................................................................................''''.....................''',,,,,,,,;    //
//    ;;;;;;;;;::::cclooddd:...................................................................................................................................................................'''''''''''''.'    //
//    ,''''........'''',;:cl:.......................................................................................................                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AMP is ERC1155Creator {
    constructor() ERC1155Creator("AlfonzoMusicPhoto", "AMP") {}
}