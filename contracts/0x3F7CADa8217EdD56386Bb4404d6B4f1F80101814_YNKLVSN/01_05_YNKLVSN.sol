// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: YankelVision
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    OOOkxxxxxxxxxxxxxxxo::cc;......................................,:ldk00OOOOkOOOkkkxxkOOOOOO    //
//    oooooolc:;,,,,'.........                                  .....';:oxO0OOOOOkkkkkkkkkkkkxxx    //
//    clcccc:;,......                                            .....';:oxOOOOOOOOOOOkkkkkkkxdx    //
//    oolcccc:;,'.......                                          ......',:ccloooodddxxkOkkkkxkk    //
//    Oxlcclc:;;'.......               ...............                      ......',;coxOkkOOOkx    //
//    Oxlccl:,,,.......         ..............',,,,,,''.....                 ......,;:lxOkkOOOkk    //
//    Oxlccl:,,,.......        ...........';:cccccccc:::;;,'..                 .....';:ldxkOOkkO    //
//    Oxlcllc::;'.......   .  ........',;:cloooooollllcccc::,.....              .....,;:ldOOOkkO    //
//    Okolccclc;,'.......  .........,:llllloooooolllllllllcc:,......            .....';:ldkOOkkO    //
//    xOOoccclc;,,'....     ...',',:looooooooddooooooollllcc:,.. ....           ......';:ldO0kxO    //
//    xOOdcccll;,,,...      ...,ccloddxxxdddxxxdddoooooolccc;'.. .....         ......',;:ldO0kxO    //
//    kOOdlllllc:;,'....    ....:ldddddddddddddooooooooolccc:,.......          ......',;coxOOkkO    //
//    kkkkOOkkkdlccccc:,'.......;llc:;;:cllllc:,,,,,,;;::cccc:,... .....        .....',;cok0Okkk    //
//    kkkkO0OOOxlccccol:,.......,;;,'...';loc;'..'''''''',;:clc,.   .....       .....',;cok00kxk    //
//    kkkkxdkkdocclc;,'.........;:,,'..'';okl,',,;;;'..'',:loll:'........       .....',;cok00kxk    //
//    kkkkkkOOkxdllllc:;;,'....,lolc:;;::cdkl;;:cccc:;;:cloddlcc;......'.   .......',;coxkxkkkxk    //
//    kkkkOOOOOkkkkkdooooo:,'.';oxxxddooooxd::clloolllooddddolc:;.....''.  .......',:cokOkdkkkkk    //
//    OOOOkxxkkxooodl:;;,'...',:ldxkOkddooxd::cloddddddooolcc:;:;.....''.';:cloooooddxxkOOkOkkkk    //
//    Okxkkddkxdlcclll:,'.....,;coxOOxoolldl;::::lodddddollcc:::;.......,;coxkOO00OOOOOOOOOOOkkk    //
//    kkkkkkxxxxdxxxdlcc::ccl:;;;;;:::cc,','..',:ccccloollccc:::,........',;cldkOO0000OOkOkkkkkk    //
//    kkkkkkkkkxxkOkxolclloddl:,'....,cl:'....';lolc:::clccc::;,...........',:lxkO0OO00OOOkkkkkk    //
//    kkkkkkkkkkkxxdllcloddl:;'...'',;:;'......',;,,,',;clc:;,'............';coxO0KOkOOO0Okkkkkk    //
//    OOkkxdxxdxkxdlcclodoc:,'....''...........''......';c:,'.............';:lxkO000OOOOOkkkkkkk    //
//    kOkkkkxxkxxollccldxo:;,....,;,..';,''...'',;;;,...,;,'............',;coxO0K0OO000kkkkkkkkk    //
//    kkkkkkkkkkxxxxdxdollccl:;'......';,'.....',;;,,'.......  .......';codxxkkOOOOkkOkkkkkkkkkk    //
//    OOOOkkkkkkkkkkkOOxdollllc;''......''''','',,,'.........  ......',:oxkOOOkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkOOOOOOkddddxdc;,,,,''...................... ..    ......',;codxxxxxxkkOOOkkkkkkkkkk    //
//    kxxxxkkkkkkkkkxkkkkxddoloooc;,,,,;,,'....               ....;;;,.......',;cldk0Okkkkkkkkkk    //
//    kxxxxkkkkkkkkkkkkkkkxdooloo:;,,,,,'....              .....'::;,.  ......',:ldk0Okkkkkkkkkx    //
//    kxkkkkkkxkkkkkkkkxxxdlolcc;''','.......            .....';cc:'.   .......,:ldk0Oxxkkkkkkkx    //
//    xxkkxkkkkkkkkkkkxolooolc:,'....  ..  ..    .        ..,;:::;.        ....',:cdxOOOkkkkkkkk    //
//    xxkkkkkkkkkkxkxdlccc:;,'...... ....        .     ..',:c::,'.         .....,;cldkOkxkOOOkkk    //
//    kkkkkkkkkkxxxxoc:cc,.........  .,;;'''',''',;;;;,;cc:;:;..           .....',;:lodxdxxkOOOk    //
//    kkkxxkkkkkkkkdllcc:,.......     .,::cloolollooollccl:'..             .... ......'',::lxxkk    //
//    OOOOkkOOOOOOkxolc;,,'.....       ..,:cccclllcc:::;,'.               ...       ..........''    //
//    OkkOOkxxddooollcc:,,,'...    ......;lollldxxolcccc;......          ..          ......   ..    //
//    kkkkxl;;,''''''''..        ..,;;;cdkOOOkOOOkkOO00Oko;,;;.        ....        ......      .    //
//    OOOxc;,,,'''.'''..        .';;;;:lkOO0OkO0OkO00O0Okkl,,'.        . ....      ......      .    //
//    kxkxl;,,'''.''''.         .,;;;;:dO00OOO0OxxOOOkOkxxx:,.      .     .       .. ...       .    //
//    lclc;,,,,;;,'.....       .';;;::ok0K0OOO0kxO0OOOkxxol:,.                                 .    //
//    ....'',,;;;;'.....      .'::::cok00K00O00OO00O0OkOo,.,,.      .        .                 .    //
//    '''''','.........       .,:::cok00KKKK0KKOkOkkOkkk:.','.     ...          .           ..      //
//    ........     ..        .,::::oO000KKK0KKOxkOOOOOOo,',,.     ...                    .  ..      //
//    .... ..                .;ccoxkO000000000kxO00OO0x,.,,,.     .        ..  ..        ..  .      //
//          .        .   .  .'::cd0K00000O0000kxkOOkO0x,.,;,.    .......  ...  ... ..     . ...     //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract YNKLVSN is ERC721Creator {
    constructor() ERC721Creator("YankelVision", "YNKLVSN") {}
}