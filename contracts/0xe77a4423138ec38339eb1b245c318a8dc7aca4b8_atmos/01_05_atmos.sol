// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Atmospherical
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ..................,cd0NWNkl;''codxdl::c:'....',:oOKXWWNXkl;,,..............,;:lc;'..................    //
//    ................',:d0NN0l,,,':oOKK0xl;:c,........',:dKNNXOo:,'.............'''''....................    //
//    ..  ..........',,:xKNNO;.',,',:lxkxl:';cc,...........,xXNNKxc,','.......'',,,'......................    //
//         ....''',,,;:xKNW0:..';;..',,;;,',cccc............'oXNNKxc;;;;;,,,,;;;::;,,''''.................    //
//         ...';;;;;;:d0NNNx'...'::;;'.,;,;loc:,'.....'.....':kNNX0xllloooooooodol:;,''',,,'''...........     //
//         ....',;:::lkXNNNd.....';clloodddl:;,''........',;::oKWNXOxxkkkkkkxxkxdl;;,;;:::;;;,''........      //
//         .....',;:cd0XNNNd......',;:ccccc:;,'........',;:::::kNNX0OOOOOOOOOkkxo:;:::cccodc:;;,'.......      //
//          ....'',;:xKXNNNx'.......',,,,,,,''........';;;:::;,lKNXK00000000OOkdl::c::cccllc::;;''.......     //
//          ....'',,:xKXNNNk'...............''........,;;;;;;,'c0NXKKKKKKKK00Okdollc::c:::::::;;,''''.....    //
//        ......'',,;d0XNNNO,..............'..........,;:;;;,,,c0NXXXXXXKKKK00kkxddolcc:;:::;;;,,,,,,'....    //
//       ......'',;,;o0XXNNK:........................';:::;;,',;dXXXXXXXXK0KK0OOOOkxdol::::;;;;;;::;,,'...    //
//       .....',,;;:cokKXNNXc.......',.',,..........';;::::;;;;:cd0XNXXXXXXKKK00OOOkkxo:::;;;;,,;c;....'..    //
//      ....'';c:::cooxOKXNXc.....  .'',;,........',,;;;;;;;;;;:::cxKNXXXXXKKKKK0OOkkxoc::;;;,,,;::,'''...    //
//      ....,;:lolllodxxOKX0:........ ...........'',,,;;;;;;,;;;;:oOKNXXXXXKKKK000OOkdlcllc:;,,,,,,,,'....    //
//       ..''cocldooddxxkO0d'........ ........'''',,,,,,,,,,,;;;;cxKNXXXXXXXKKK00000kdolllc:;,,,,,''......    //
//      ...'.'cllddddxxkkkx:................''',,,,,,,,,,,,;;;;,;oKNNXXXXXXXXKKKKKK0Odlllclc:;;,,''.......    //
//      ....';cododxxxkkOko,.............',,,'',,;;;;;;;;,;;;;;;ckXNNNXXXXXXXXXXKKK0Oxollclc::;;,'.......     //
//      ....',lodddxxxkO0Ol'''...........,;;,,,,,,'''',;:clcc::lONNNNNNNNNNNNXXXXXK0OOkxdddoc:;;,,,'.....     //
//      .....';oddxxxkOO00l,,'..........,;;;;;;;,.....',,oKXK00XNNNNNNNNNNNNNNNXXXXKK000Okkxdol:;,',,'...     //
//     ......';ldxxxkkkO00x:,'........'',,;;;;;;'..','''.:0WNNWNNNNNNNNNNNNNNNNNXXXXXKKKK0Okkxxol:;;,,'..     //
//     .......,cdxxkOkxkOK0o,'''...,;,,,,,,;;;,,,;;,,'',;oKWNNWWWWNWNNNNNNNNNNNNNXXXXXKKK00Okkkdolc:;,'...    //
//    .......',:xkkxxxkkOxO0l,,,;clc;,,,,,,,,'',,,cloooxOKNNNNNWNWWWWNNNNNNNNNNNNNXXXXKKKK0OOkxxxolc:;'...    //
//    ......',;:codddkkkkxx0Oddxxoc:;;,,,;,''',,,,;;coxkOOKXKK0KKXNWNWWNNNNNNNNXXNNXXXKKKK00OOkxxdolc;,...    //
//     ....',;:llcoxkkkkkkxodddolcccc::::::,.';:::::ccllloooollloox0XNWNNNNNNNNNNNXXXKKKKK000OOkkxdol:,'..    //
//     ...',;:codoclxkxdddoc;;:::::::::;;;;;,,:;;;;;;;;;;;;;::::::clxXWWWNNNNNNNNNXXXXXXXKK00OOOkxxdo:,'..    //
//     ..',,;codxkd:coollcc:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ckNWWWWNNNNNNNXXXNNXXKKKK00OOkxdl:,'..    //
//    ...',;:ldxkOOo::c:;,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,;xNWWNNNNNNNNNNNNNNXXXKKKKK0Okxdl:,'..    //
//    ...',:lodxkOOxc::;,'',,,,,,,,,,;;;;;;;;;;;;;;;;;,,,,,'''',,',':OWWWNNNNNNNNNNNNNNXXXKKKK00Okxdl;'...    //
//    ..',;codxxkO0klcc:;'..'''''''',,,,,,;;;;:;;,,::,,,,,,'.''..'''oXWWWWNNNNNNNNNNNNXXXKKKK00Okxdoc;'...    //
//    ..',:lodxkkO0klllc:'.....'''''',,;;;odllodo:',;;,,,,,'.......c0WWWWWWWWNNNNNNNNNXXKKKKK0Okxdol:,'...    //
//    ..',:ldxxkkO0kllllc'......''',;l:cooxoldxxxo::lc;;;;,,'....';dXWWWWWWWNNNNNNNNNXXKKKKK0Okxdol:;,'...    //
//    ..';:ldxkkkOOxllllc;.......',:cooooodddddkkdoxxocloc;,''..,::kNWWWWWNNNNNNNNNNNXXKKKK0OOkxdoc:,'....    //
//    ..';:ldxkkOOOdlllll:;,.....'';cldxkxdddooddoxOkoolc:;,'...,:cONWWWNNNNNNNNNNNNXXKKK00Okkxddlc;,.....    //
//    ..',:ldxxkkOkocllllc:;......',;coxxxxxxxocloddclc;'''''...':l0WWNNNNNNNNNNNNNXXXXK0OOkkxdolc:;''....    //
//    ...';codxxkkdlclllll:;'.  ......'',::clo:;:oxxdd;.........;:dKNNNNNNNNNNNNNNNXXXK0OOkxxdooc:;,'''...    //
//    ...';cooddxdlcclllllccc,............':lodolcoxxl,.......';:cxXNNNXXXXNNXXXXKKKK0OOkkxddollc;,,''....    //
//     ..',:looddoccccllllccdx:...........,lxxdoollooc'......';::ckXXXKKKKXXKKK0000OOkkxxddoollc:;,,''....    //
//     ...',:cloolcccclllllcd0x:........':looloolcc:;'.......;::clkKK00000000OOOOOkkxxxddoolcc::;,,''....     //
//     ....',;;cllc:cccllllldkOd:'.....'clcc::c;............,:cc:lk0OOOOOOkkkkkkkxxxddoolccc::;;,'''.....     //
//     ......',;lc:::cccllcloxxdoc,...'clllc:'..............;:::cldkkkkxxxxxxdddddooolcc::;;;,,,''........    //
//    ........';cc:::ccccccloodool:,..;;,,,;,..... ........;ccclooodddddooollcccccc::;;;,,'',','..........    //
//     .......',;c:::::cccccllccllc:,............... ....'colcllllooooooolc:;;;;;;;,''''.','''............    //
//       ......'';:::::::ccl:;;;:ll::,. ......'''......';:looolllllllllllollc;'',,,''''..''........''.....    //
//        .......',;:;:::cc:,,,,:ll:,'.  ...'',;,'.....';:llcclllllccccclloool:,'''.............''''.....     //
//          .......',;;::c;'''',col:'...  ....''....  .',;cc;;,,;;;,,,;loooolllc;'''..................        //
//            ......'',;;'...'':lc:;............. .. ...',::;'..'..''':ooooolllcc,'''................         //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract atmos is ERC721Creator {
    constructor() ERC721Creator("Atmospherical", "atmos") {}
}