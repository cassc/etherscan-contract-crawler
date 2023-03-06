// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Power Cables
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                              //
//                                                                                                                              //
//     ..................',:lodxdddddddddxkxddododdddxxxdddooolllllooddollllllllllloolc:::;;;;;;:loddddollccc:;,,'''........    //
//    ...',,,,'',,,,,,,;:ccodxkkkkkxxxdxkOOkxddddoooodxkxxxddoooooooooolllccccclllloollcc:::::ccloddxdocccooxd:clccc::::;,'.    //
//    ...,,,,,',,;,,;;;:clodddxxxxddoooodxkOkxdddooooodkkxxxxddddooooodolllllllllooooooollllloodddddddolcoxx0xdkd:lxlcxd;''.    //
//    ............'',;;:clodddxxxddooooodxkkxddddooooodxxxxxxxxxxdddddxdooooddddkkxxxddxxxkkxxxddolllllllxxkOdodl,cl;co:,'''    //
//    ..........'',;:clooddddxxxxdddddxxxkkkxdooooooddxxxxdxxxxxxxxxxxkkkkkkkOOOOkxxxkkkOOOOkxdollccc:ccooccc:::c:c:;:;'''''    //
//    ........'',;:lodxxxxxxxxkkxxdxxxkkkOOkxddddddoolc:;;,,,'''',''',,;::cloxOOOkxdxxxxkkkxxdollcccc::ccc:::::::cc:;,,,,,''    //
//    ......'',;:codxxxxkkkkkkkkkkkkkkOO000OOOxoc:,'.........................,:::ccooddddddddoolllccccccccccllllllc:;;,,,,,,    //
//    .....',,;clodxxxxxxkOOOO00000000000K0koc,..........',,,,;;:::;;;;;'...........,:coodddxxdolllllccclloxxddoolc::;;,,,,,    //
//    ....',;:coodxxxxxdxxkkOOOO0000K0K0ko;.........';:cokOkxooddddddx0KOdlc:;,........';cdxkkxdooolllllodxkkkkxdocc::;;;;,,    //
//    .''',;::cloddxkkxxkkOOkOOOOO00K0xc.    ..':lllooddx00Oxlccllllld0XKOxxxxxxoc,.......;lxOkxddddddddxxxddxxxxdlcc:;;;;;;    //
//    ',,,;;::cloodxkOOO00K000000000x:.     .'cdOOxooooox00Odc:::::::oOKKOxddxk0KKOo;'......'cxOOkkkkkkkxddooodxxdolcc::;;;;    //
//    ,;;;;:::ccodxkO000KKKKKKKKXKOo:'.   .';cdxkOxoloookO0Odc;:;;:::lkKKOxdddk00K0xolc;......'ck00KKK00kxddooddddolcc::::::    //
//    ,::::::cccloxkO000KKKKKXKKOo,'.....,;;:coxkkxollloxOOkdc;;;;;;;cx0KOxdodkO00Odllodo:......,oO0KKXNXKOxxddodddollcc::cc    //
//    ,;:::::cccloxkO000KKKKKXKx;. ...';::;;:cldxxxolllokOOkxollooooodk0K0kdodkOOOxollllooc,......:x0KXXXXX0Oxdddddddollcccc    //
//    ,;::ccccccloxkO000KKXXX0o'..  .';:::;;:clooddolccokOOOO00KKKKKKKXXXK0Oxxkkkxdolcccllll:,....':xKXKKXXXKOkxddddxddolccc    //
//    ,;;:ccllllodxkO0KKKKKKOc...  .,;;;;;;;;:cccccccldkOOOOOOOO000000KKKK0KKOxdooolcccccclllc'....';xKXXXXKK0Okxdddxxkkxoll    //
//    ,;;::ccllodxkkOO000KKO:.  ...:ccc:::::ccllllccok00OO000OOkkkkkO0KXKK0O0Kkooooollllloodddl,.   ..o0KXKK00000kxxddxO0Oxo    //
//    llcccccclooddddxxkkOk:.    .:lllccccccllooooccoO0kkkO0KK0Okkkk0KK0OkO00XKkddooolloddxxxxdl,.    .o00KKKKKK0OOkxxxkkkkx    //
//    ooooollccccclllloodd:.    .,:::::::::cclllcc::d0OxxkOkO0KOxxxk0K0OOOkkOKKxolllllllooddddolc,.....,x000KKXXKK0OOkkkxxxx    //
//    ;:ccllcccccllllooooc.     .,;,,,,,,,,;;::;;;;:oxdldkkkxk0kdxxdkOkOkOxodOkocc:::::::::ccc::;;......lO000KXXXXK0OOOkkkkx    //
//    ,;:cllllllloooodddd;.    ..',;;;;;;;:cclc;;;;coxxdldkOkkkdxOkxxkkOOkdoxkkxoc:::::::ccccc:;;;'. ...,d0000KKKK00OOOOOkkk    //
//    :clloodddoooodddxxo,.   .';::cc:::ccloodl:;;;lddxxdodxkxddddddddkkkxdxxxxxocccccclooddxxxddol:'''''l0K00KKK000OOOOkkkk    //
//    :looooddxxxdxxkkOOo'..  .;cccc:;;;::clolc;;;;codddxdddddxxxxxxxddddxxxxxddl::cccccllooodoooll:'....:k00KKKK00OOOkkkkkx    //
//    ;:ccclldxxkkkOO0KKo......;;::;;;,,;;:ccc:;;;;:cloddddolcclodddoc:lodxxxdol:::;;;;;;:::::;;;;;,. ...,dKKXXK0Okkkxxxkxdo    //
//    ;;;;:clodddxxkO0K0l.....';;::cc::::cclll::;;;;::coddddoc:;;;;;;:loddxxdlc::::;;;;::cclllc::;;;.....'dKXXXKKOkkxxddxxol    //
//    ;:::ccldddddxxkkkkc.....,;:::cc::cclodxdoccc:;;;:ldxxddddollloodddddxdlc:cccccccccllodddolc:;;.....,dXXKKK0Okkxddddxdo    //
//    ,;:clldxkxdddxxxkxc.....,;;;::::;::clodocc:::;;:lddddxddxxxxxxddxxxxxdc:ccccc::::ccllooolc:::;.....,dKKKKK00Okkxxddxxd    //
//    ,;:clloxxxxxddxxkko,....';;;;;;;,,:ccccc:;;;;;cokkkkxddxxxxxxxxxxxxkkOxlc:::;;;;;;;::::::;;;;,.....'oOOOOOOkkkkxxxxxxd    //
//    ,;:clloooddxxxxkkOd;'....',;;:;:cloocloc:cloodkOOkOkkxxxdxxxxxxxxkkOO0K0Oxdl:;;;;;;;::::::;;;'.....'dkxxxxxxxddddddddd    //
//    ,;;:lodddddddxxkOOkc''...',;:c:codollloxkO000OkkkOOkkkkxddddddxxkkkO0KKKKK0Okl::;;;:::cool:;;.... .:xxxxxxxddddooollll    //
//    ,,,;:coxkkxdooodkOOd,....':loooc:::::cdOOO0OkkxddxxkkkkkxddddxxkkkOO00Okkkk0Kxc:;;;::cddolc:,.....'dOOkxxxxddddoooolll    //
//    ,,,,;;;cldddollldk00o;;,'':lddolc::::oxxxxxkkkxdoloodxkkkxxdxxkkkkxxxxxxxk0KX0dc::;:codddlc;......o000Okkxxddddddoooll    //
//    ,,,,,,;;;::ccccloxkkkocc:,,lddolc:::coxdoddxkkkkxxddooodxkxxxkxdooodxkkkxkKXNNOdlc:cldddolc'.....:k000OOOkxxxxxxxdollc    //
//    '''',,,;;;;::ccloooodl;,:lllodlcccccllllllodxkOOOOkkxddodxkkkdooodxxkkkxxOKKXX0olccloooooc,.....,dOOkkkkkkkkOOOOkkdllc    //
//    .'''',,;;;;;:::cclllloc'.,;;;cc::cllllllcclodkkO00OOOOkkxxkkxdxxxkkkkkkkxkO000Odccllolcll;.....,dOOkkxxxxkkOOOOOOkdllc    //
//    ..'''',,,,;;:::ccccclll:.......,;::cokxolllldxkkOO0000000OkkkOOOOkkkkkkkxkkkO0XKxlllllc:,.....;xOOkkkxxxxxxxxxkkOkxdol    //
//    ...''',,,;;;;:::cccccccl:'.    ..',:dOkdddoloxxkkOO000000OkxO000000OOOOkkxkOKXNNKdlcll:,''..'lk00OOkxxxddddddxxkkkxdol    //
//    ...',,,,,,,,;;::::::ccccc:,.    ...lkOkxddollodxxxkkOOO00OkkkOOOOO000OOOOO0KXNWNNOlc:;,,,,,:xKK00Okkxdddooooddxxxxxoc:    //
//    ....''''',,,;;:::::::cccccc:'.    .,lxkkdoooccclodxxxkkkOOO000OOOOOOOOkkkkOKKXXXX0l,,,,,,:d0XX0OOkxxxxddoolllllllllc::    //
//    ..'''''''',,,;::::cccllllccc:,.. ....':odooolccccclloddxxkkkkkOO00OkkxxxxxkO00Oxo:,,;::cd0XNXX0Okkxxxxxxdollccccccc::;    //
//    ..''',''''',,;;::::cccc::;;,,,,.........',:cc:::::ccclloddxxxxkkkkxxxddddddol:,...',;cdO0KKXXXKOkkxxxxxxdolcccc:ccc:::    //
//    .......''''',,;;,,,,,,,,,''''''''..  ...  ....',;;:cllllooooodkkkxxdddol:;'.........,lddxk0KKKOkkxddddxxdolcc:::::ccll    //
//    .........'',,,,,,,,'''''''''''''... ..         .....',;::c:::ccclc:;,'.........    ..,:lodxOOkxdddooddxdollcccccccccll    //
//    .........'',;,,'''''''''',,''''.. .......            .......................          .;lodxddoooooodxdolcccc::::;;;;;    //
//    ..........',,,,,',,,,,,,,,,,''..  .........       .....................''.........     .cdxkxdoooooodxdllc::;;;;;,,,,,    //
//    ...........',,,''''',,,,,;;;,,'. .. .......  .........................''................cdkOkddollllooolc:;;;;,,,,,,''    //
//    ............'''''''''',,,;;;;;'........................................................,lddxxolcccccccc::;;;,,,,,,,,''    //
//     .................''''''',,;;,'..........  ............................................;looooc:::;::::::;;;;,,,,,;;,,,    //
//       .......................'',,'........................................................':cccc:;;;;;;;::::;;;;;;;;::::;    //
//          .......................''....  ... ..............................................'::ccc:;;;;;::::::::;;:::cllccc    //
//             ........................     ..     ..................................   ....';::::::::::;;;;;;;:::::ccllllll    //
//               .......................     ...     ......             ......  ...      ..,:::;;;;;;;;;;;,,,,,,,;;;::cllcc:    //
//                 ........................    ..     .....                .     ...  ...',;;;;;,,,,,,,,;,,,,'''''''',;:::;,    //
//       .. .. ..................................                                 ..''',;;;;;;;;,,''''''''','''.......',,,''    //
//      'l:.::,:c,,c;:ccl:'.............................                   .......',;::;;;;;;;;;,''''''''..''...............    //
//      ,kl,odlcl:cxloOOdl,...................'''',,''''''..............'''',,,,,,,,,;;;;,,,,,''''''........................    //
//      .,,,;;;;:;,:;;;;;,. ...................''',,''',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,''''...........................     //
//                           ....................',,'''''',,,,,,,,,,,,,,,,,,,,,,'''''''''''''''..........................       //
//                             ..................,,'''''''',,,'''''''''''''''''''''''''''.............................          //
//                                                                                                                              //
//                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PowerCables is ERC721Creator {
    constructor() ERC721Creator("Power Cables", "PowerCables") {}
}