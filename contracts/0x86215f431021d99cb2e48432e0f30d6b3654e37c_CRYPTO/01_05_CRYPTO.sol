// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Notables
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllllccc::::::;;;;;;;;;::cllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllcc::::;;,,,,,,,,,,,,,,,,,,,,;;:ccllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllcc:;,,,,,,,,,,,'',,,,,,,,,,,,,,,,,,,;::clllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllcc:;,,,,,,,,,,,,,,,,,,,,''',,,,,,,,,,,,,,,,,;:cllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllcc:;,,''',,,,,,,,,,,,,,,,,,,,'''',,,,,,,,,,,,,,,,,;:clllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllc;,'''''''''',,,,,,,,,,,,,,,,,,,''',,,,,,,,,,,,,,,,,,,;clllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllc;'''''''''''''''''',,,,,,,,,,,,,'',,,,,,,,,,,,,,,,,,,,,;:llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll:''''''''''''''''''''''',,,,,,,,,''',,,,,,,,,,,,,,,,,,,,,,;cllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllc,''''''''''''''''''''''''''',,,,,''',,,,,,,,,,,,,,,,,,,,,,,;clllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllc;'''''''''''''''''''''''''''''''''''',,,,,,,,,,,,,,,,,,,,,,,,,:llllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllll:'.....'''''''''''''''''''''''''''''''',,,,,,,,,,,,,,,,,,,,,''';clllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllc:;'.....''''''''''''''''''''''''''''''''''''''''''''',,,,','',,'':llllllllllllllllllllllll    //
//    lllllllllllllllllllllllllc:;,''..........'''''''''''''''''''''....''''''''''''''''''''''''''''':llllllllllllllllllllllll    //
//    lllllllllllllllllllllcc;,'....................''''''''''''.......',;,,''''''''''''''''''''''..,cllllllllllllllllllllllll    //
//    llllllllllllllllllc:;'............................''............;clllcc:;;,,''''''''''''''....,cllllllllllllllllllllllll    //
//    llllllllllllllll:;'........',;;'..............................',,;;clllloooolc::;,,''''''''''';lllllllllllllllllllllllll    //
//    lllllllllllllll:'.......';cllll;,::,'.................',;:cccllllllclloodddddddddoollcc:::;,',clllllllllllllllllllllllll    //
//    lllllllllllllll;.....';clllllllccccccc:;;::,',,,,,,'';;::::ccccllllloodddddddddddddddddddddl:cllllllllllllllllllllllllll    //
//    lllllllllllllllc,.';cllllllllllc;;cc;'''';:cllllll:;coo:....,;clcloddddddddddddddddddddddddlclllllllllllllllllllllllllll    //
//    llllllllllllllllcccllllllllllllc::dkd;...cllolllllclOKX0o;,:clododddddddddddddddoolooooooolcccllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllcldxxdc:lddddddooollxkkkxdddddddddddddddddddddddlccclllloolloollllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllcldxxxdoodddddddddddddddddddddddddddddddddddddddoc::cloollllcclolllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllcldxxddddddddddddddddddddxddxxxxdddddddddddddooo:;;;colccclllccllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllloxxdddddddddddddddddddddddddddddddddddddddddol:;;;:ll:cclcloccllclllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllloxddddddddddddddddddddddddddddddddddddddooooc;;;;;:lc:cloooooollllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllcodooooddddddddooddddddddddddddddddddddooollc;;;;;:c::::cloooolclllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllccoolcloooolllollodddddddddddddddddddooool:;;;;;;;coolllllllcclllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllc:cdoc:::c:;,,;:clloooodddddddddddoooollc:;;;;;;,;lddollcccclllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllc::lc:;;,,,,,,,,,;;::;:clloooooooolccc:;;;;;;;;,',:ccc:clllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllc;,;:;;;;,,,,,,,,,,;;;;;;::::cccc:;;;;;;;;;;;,,',:cllccllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllc:;;;,,;::::;;;,,,,,,;;;;;;;;;;;;;;;;;;;;;,,,,,':ooooccllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllc;,,:lloooollllcc:::;;,,,,,;;;;;;;;,,,,,,,,,'',coddoccllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllc;,coocccccooddoooooc,',,,,,,,;;;;,,,,,,,''';codddlclllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllc;;c:;;;;;cooooollc:;;;;,,,,,,,,,,,'''''',;cddddolclllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllc;;;;:;;;;;;::::;;;;;;,,,,,,,,,,,,'''''';coddddoolclllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllc;;;;;;;;;;;;;;;;,,,,,,,,,,,,,',,,,,,',coddddddoccllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllc:;;;;;;;;;,,,;,,,,,,',''''';:::ccccccoddddddddo:;llllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllll:;,;;;;;;;,''','',,;::::cclooollllccoddddddddddlcclllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllc:;;,,;;;;,';:::cclooodddddddollcloddddddddddddlclllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllll::ccllc:;cloooooddddddddddolllodddddddddddddoccllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllccoddddddddddddddddollodddddddddddddoo:'',:cllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllclodddddddddddddddollloddddddoolcc:;,,.....:llllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllc;codooooooooooooolloooool:;,'............,clllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllll,'cooooooooooooolloooc:,..................,cllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllll:;ccoooooooooolllol:,.......................;cllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllll:;ccloooooooooolc;'..........................':lllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllc:clllloooooool:,...............................;clllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllcclooolloool:;,..................................,cllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllc:coooooool:,......................................':lllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllc:cloooool:,..........................................;clllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllccclooolc:,'.............................................,cllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllc:;:ccc:;,..................................................,clllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllll:'............................................................,cllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllll,..............................................................;llllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllc'..............................................................'clllllllllllllll    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CRYPTO is ERC1155Creator {
    constructor() ERC1155Creator("Notables", "CRYPTO") {}
}