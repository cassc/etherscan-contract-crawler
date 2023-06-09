// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fantasy Women Portraits
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    OOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkOOOOO000KKKKKK0000000000000000OOOkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOO0000000000000000K000KKKKKKKKKKXXXXKKKKKKKKKKK0000    //
//    OOOOOOOOOOOOOOOOOOOOOOOkkOkkkkkkOOOOOOOO00KKKKKKK00000000000000OOOOOkkOOOOOOOkkkOOOOOOOOOOOOOOOOOOkkkOOOO00000000000KKKKKKKKKKKKXXXKKKKKKKKKKKKKK0000K    //
//    OOOOOOOOOOOOOOOOOOOOOOkOOkkkkOOOOOOOO000KKKKKKKKK000000000000OOOOkkkkkOOOOOOOOOOOO0000KKKKKK000OkkxdodxkkkkkOOO00000KKKKKKKXXXXKKKKKKKKKKKKKKKK000KKKK    //
//    OOOOOOOOOOOOOOOOOOOOkkkkkkkOOOOOOOO00KKKKKKKKKKK00000000000OOOOkkkkkkkOOOOOOO00KKKKXXXXXXKKK00OOkxdoccldkkkkkxkkkOO0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    OOOOOOOOOOOOOOOOOkkkkkkkkkOOOOOOO00KKKKKKKKKKK0000000000OOOOOOkkkkkkOOOOO0KKKXXXXXXXXXXKKK00OOkkkxdol::cdxxxxxxxxxxkkO0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    OOOOOOOOOOOOOOOkkkkkkkkkkkOOOOO00KKKKKKKKKKK00000000000OOOOOkkkkkOOOOO0KKXXXXXXXXXXXKKK000OOOkkkkxxdl:;;lxxxxddddddddxkkO0KKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    OOOOOOOOOOOOOkkkkkkkkkkkkOOOOO000KKKKKKKKK00000000000OOOOOOkkOOOOOOO0KXXXXKKKXXXKKKKK000OOOkkkxxxddoc;,,:dxxxddoooooodddxkO00KKKKKKKKKKKKKKKKKKKKKKKKX    //
//    OOOOOOOOOOOOkkkkkkkkkkkkOOOOO00KKKKKKKKK000000000000OOOOOkkOOOOOOO0KXXKKKKKXXKKKKK0000OOOkkkxxxxxddoc;,';lxxxxddooooooooodxkO0KKKKKKKKKKKKKKKKKKKKXXXX    //
//    OOOOOOOOOOkkkkkkkkkkkkOOOOOO00KKKKKKKK00000000000OOOOOkkkOOOOOOO0KKKKKKKKKKKKKKK000OOOOkkkkkxxxxddoc:;,',cdxxddooooolllllooodxO0KKKKKKKKKKKKKKKKXXXXXX    //
//    OOOOOOOOOkOOOOOOOOOOOOOOOO00KKKKKKK00000000000OOOOOkkkkkOOOOOOO0KKKKKKKKKKKKKKK00OOOkkkkkkkxxxxxdolc:;;,':oxxxdoooollllllllooodk0KKKKKKKKKKKKKKXXXXXXX    //
//    OOOOOOOOOOOOOOO0000OOOOO00KKK000000000000000OOOOkkkkkkkO0OOOO0KKKKKKKKKKKKKKK00Okkkkkkkkkkxxxxddoolc:;,,';ldddddoollllllllllllooxO0KKKKKKKKKKKKXXXXXXX    //
//    OOOOOOO00OOO00KKKK000000KKK0000000000000OOOOOkkkkkkkkkO0OkOO0KKKK000000KKK000Okkkkkkkkkkkxxxxddollc::,''',ldddddoollllllllllllllodk0KKKKKKKKKKKXXXXXXX    //
//    OOO000KKKKKKKKKKK000000KK0000000000000OOOOOkkkkkkkkkkO0OkOO000000000000000OOkkkkkkkkkkkxxxxdddoolcc:;,''',cdddddoolllllllllllllllldk0KKKKKKKKKXXXXXXKK    //
//    O00KKKKKKKKKKKK00000KK000000000000000OOOOOOkkkkkkkkkO0OkOO00O00000000000OOkkkkkkkkkkkxxxxxdddoollcc:;,'''':odddoolllllllclllccclllldk0KKKKKKKKXXXXKKXK    //
//    0KKKKKKKKKKKKK00KKKK0KKKK000000000000OOOOOOOkkkkkkkO0OkO00OOO0OOOO0000Okkkxxkkkkkkkxxxxxddddoolcc::;;,'''':oxddoollccccccccccccccllldk0KKKKKKKXXXXXXXX    //
//    KKKKKKKKK00KKKKKKKKKKKKK00000000000000000OOOkkkkkOOO0OO00OOOOOOOO000Okkkkxxkkkkkxxxxxddddooolc::;;;;,''''';ldddolc::::::::ccccccclllldk0KKKKKXXXXXXXXX    //
//    KKKKKKKKKKKKKKKKKKKKKKK000000000000000000OOOOOOOOOO0OO00OOkOOOOO0OOkxkkkxxkkkkkxxxxdddollc::;;,,,,,,,''''',;:c:;,''...'',,,;:cccccllloxO0KKXXXXXXXXXXX    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00OOOOOOOOO00000OOkkkOOOOOkxxxkxxxxkkxxxxxdoollc:;;,,,'',,,,,'''''',,;;,,,,,,,,'''''',;:ccccclloxOKXXXXXXXXXXXX    //
//    KKKKKKKKKKKKKKKKKKKKKXXXXKKKKKKKKKKKKK000OOOOOO0000000OOkkkOOOkxdddxxxxxxxxxxxxdolcc::;,,,,;;;;,,,,,,,,,,,;;::cccccccc::;,,''',;:cccllldk0KXXXXNXXXXXX    //
//    KKKKKKKKKKK0000KKXXXXXXXXXKKKKKKKKKK0000OOOO0000KKKKK0OOkkkkkxdooddxxxxxxxxxxxdlc::;,,,;:cloooooollcccccclloodddddooooollc:;,'',;:ccllloxOKXXXNNXXXXXX    //
//    KKKKKKKK00000KKKXXXXXXXXXXXXXKKKKK000000OO0000KKKKKK0Okkkkkxxdooodxxxdxxxxxdxdl:;;,,,:coddxxkkkkkkkxxxxxxxxxxxxxxxxdddddoolc:;',,;:ccllloxOKXXNNNNNNNN    //
//    KKKKK0000KKKKXXXXXXXXXXXXXXXXKKK00000000000KKKKKKXXKOOkkkkxxolloodxxxdxxdddxdl;;;,';codxkkOOOOOOOOOOOOOkkkkkkkkkkxxxxxxdddool:,,,;;:cllloxk0KXXNNNNNNN    //
//    KKKKKKKKKKKXXXXXXXXXXXXXXXXKKK0000000000KKKKKKKKXXK0Okkkxxxocclodxxxddddddddl;,;,';ldxkkkOOOOO000OOOOOOOOOOOkkkkkkkxxxxxxddooc:,,,;::cllldkOKXXXXNNNNN    //
//    KKKKKKKXXXXXXXXXXXXXXXXXXKKK000000KKKKKKKKKKKKKKXK0OOkkxxxoc:loodxxxddddddol;',,',cdxkkkOOOOOOOOOOOOOOOOOOOOOkkkkkkkxxxxxxddolc;,,;;:cclloxO0KXXXNNNNN    //
//    KKXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKK0OOkkxxxoc:clodxxxxxddddo:,,,,',:oxkkkOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkxxxxxxddol:,,,;:ccllodk0KXXXNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKK0OOkkxxxoc::clodxxxxddddoc,,,,'':ldxkkOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkxxxxddoc;,,;::cclldkOKXXNNNNNN    //
//    XXXXXXXXXNNNNNXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKK00OOkkxxxol::clodxxxxxdddoc;;:;'';cdxkkOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkxxxdol:,',;:cclloxO0XXNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKXXXXXKKKKK0OOOkkxxxol:;:llodxxxxdddol::;,'.,:oxkkkOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxddlc,',;;:clloxO0KXNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXKKKKKKKKXXXXXXXXXKKKK0OOOkkxxxol:;:clooxkxxdddolcc:'..';cdxkOOOOOOOOkkkkkkkkkkkkkkkkkkkkxxxkkkkkkkkkkxxdoc;'',;;cllldk0KXNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK000OOkkkxxdol:,;cclodkkxxdddlcc:'...,:ldkkOOOOOOOkkkkkkkkkxxxxxxxxxxxxxxxxxxkkkkkxxxddoc;'.',;:clloxOKXNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK000OOOkkkxxddl:;;:clodxkxxdddoc::,..'',:ldxxxkkkkkkkkkkxxxxxxxxxxxxxxxxxxxddddoolcc::::::;,'..,;:cllodOKXNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK00OOOkkkkkxdol:;;:cloxkkxxddddlc:,...'',;:::::;;;;;::cclloddddddddddddddolc:;,,'''',,,,,,,'''..',;:clldkKXNNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK00OOOkkkkkxdlc:;::codxOkkxxxddoc:;.....'',,,,,'''.......'',;clooooooooolc:,'.....''''''.....'''..,;:cllox0XNNNNNN    //
//    XXXXXXXXXXNNXXXXXXXXXXXXXXXXXXXXXKK000OOOkkkkkxdlc:::clodxOOxxxxddoc::'............'',,,,,'''.'',;:cloooooll:;,''''',,,,,'.....',;;,..';:cclodOKNNNNNN    //
//    XXXXXXXXXXNNXXXXXXXXXXXXXXXXXXXKKK00OOOkkkkkkxdlc::cclodkOkxxxxddoc:c;...''''.......,;;;;;,'''''',;:ldxxxolc;,,,''',,;;;,'....,;:::,...,;:clodkKXNNNNN    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKK00OOOOkkkkkxxdlcc:clodxkOkxxxxxdoc;:c,..',,,,,'.....',,,,,''..',,,;:ok00kdlc:;;,'...''''......':cl:'...';:clodk0XXXXXX    //
//    XXXXXXXXKXXXXXXXXXXXXXXXXXXXKK00OOOOkkkkkxxxolccclloxkkkxxxxxxdoc;;cc'..',;;:;'..............',:cccldk0KOxdlccc:;'..........';cool:....';:clldxOXXXXXX    //
//    XXXXXXXKXXXXXXXXXXXXXXXXXXKKK0OOOOkkkkkkxxdolccllodkOkxxxxxxxdl:;':l:. ..,::ccc:;,.........',:lododdxkKK0kxdoodolc;,''.''',;codool,....,;;:cloxOKXXXXX    //
//    XXXXXXKXXXXXXXXXXXXXXXXXXKK0OOOOOkkkkkxxxdollllodxOkxxxxxxxxdl:,',cl;.  .';:clllcc:;,,,,,,;cldxkkxxxxkKX0kxdddxxxdolc::::clooddol:....',;;:clodOKXXXXN    //
//    XXXXKXXXXXXXXXXXXXXXXXXKK00OOOOkkkkkkxxxdolloodkOOkxxxxxxxxdl:'.':ol'.  ..,::clooooolllloodxkkOOkkxxkk0K0kxxdxkkkkxxddddddddddooc,....';;;:clodk0KKXNN    //
//    XXXXXXXXXXXNNNXXXXXXXKK00OOOOOkkkkkkxxddooodxkOOkxxxxxxxxxol;..';lo:..   ..,;cloodddddxxxxkkOOOOOkxxkO0K0kxddxkkOOkkkkxxxxxddool;....',;;:cclodkO0KNNN    //
//    XXXXXXNNNNNNNNNNNNXXKK0OOOOOOOOkkkxxxdooodxkOOkxddxxxkxxdoc;...,coo:........':clodddxxxxkkOOO00Okxxxxk0K0kxdddkOOOOOkkkkxxddool:'....';;::cllodkO0KNNN    //
//    XXNNNNNNNNNNNNNNNNXK0OOOOOOOOOOkkxxxddddkOOOkxddxxxxxxxdoc,...':odl;'........,:loodddxxxkkOOO00OkxxxxkOOOkxxddxOOOOOOkkkxxdoolc,....',:::cllloxkOO0XNN    //
//    NNNNNNNNNNNNNNNNXK00OOOOOOOOOOkkxxdddxkOOkxxddxxxxxxxddoc,....;odol;,...... ..;cloodddxxkkOOO00OOxxxxxkOkxddodkO00OOOkkxxddolc;'....,;::clllloxkOOO0KX    //
//    NNNNNXXXXXXXXXK00OOOOOOOOOOOOOkkxxkkOOOkxdddxxxxxxxdddoc'....;lddoc:,'........':clooddxxkkOOOO000kdlcldddl::cdO000OOOkkxxdool:,....,;:clllllldxkkkkO0K    //
//    XXXXXXXXXXXK00OOOOOOOO0000OOOkkkO00Okxxdddxxxxxxxxxxdl:'....;ldddlc:;'.........,:llooddxxkkOOOO000Oxlc:;;;:cdkO000OOkkkxddolc,....,::cooolllldxkkkkkOO    //
//    XXXXXXXKK00OOOOOOO00000000OOO0000Okxddddxxxxxxxxxxddl;'....;ldddocc:;,'.........,:llodddxkkkkkkOOOOOkoc;;coxkOOkkkkkkkxddolc;'..',;:coddolccloxxkxxkkk    //
//    XXXKK00OOOO00000KKKKK000000KK0OOkxdodxxxkxxxxxxxxdoc,....':oddddlcc:;,,'.........,:cloddxxxxxdoodxxolcc::::coddoodxxxxddolc;'..',;clddddllcclodxxxdxkk    //
//    KK00OOO00000KKKKKKKKKKKKKK0Okkxddddxkkkkxxxxxxxxdl;'...';ldddxdoccc:;,,,'.........,:cloddxxxdddol:,'..'''...',cdxxxxdddolc;'..',;cldddoolcccclddddddxk    //
//    OOOO000000KKKKKKKKK00000Okxxddddxkkkkkxxxxxxxxdoc,'.',;coxddxdocccc:;;,,,'.........';clooddxxxxkkoc;,,,,,,,,;lxkkxxddoolc,...',;cloooooolcccclododdddd    //
//    00000000KKKKK000000OOkkxxxddxkkkkkkkxxxxxxxxxdl;,',;:codxdxxxolcccc:;;,,,'..........',:cloddxxkkkkxl:;,,,,,;ldxxxxddooc:'...',;:cloooollcccccclooooddd    //
//    00000KKK0000000OOOkkxxxxxkkkkkkxkkkxxxxxxxxdl:;,,;:clodddxxxdlcccc:;;;,,,,''.........'',:coddxxkkkkxolcccccldxxxxddol:,....'';:clllllollccccc:cooloood    //
//    KKKKK000000OOOkkkxxxkkO00Okkxkkkkkkkxxxxxdoc;,,:cccoddddxxxdolcccc:;;;,,'',''.......'''',;:lodxxkkkkkxxxxxxxkkkxddoc;'....'',:cclolllollccccc:colllloo    //
//    KK00000OOOkkkkkkkkO0KK0Okkkkkkkkkkkkkxxdol:;,;cccldddddxxxxolcclc:;;;;,,'',,'......''',,,,,;:lodxkkkkkkkkkkkxxxdoc:,.....'',;:cclollllllcccccccollllll    //
//    000OOOkkkkkkkOO0KKK0OkkkkkkkOOOkkkkxxdolc:;;ccccodddddxxxxolccll::;;,,,'.';,,......'',,;;;;;;;:coddxxxxxxxxddooc:,''....'',,:cccoollllllcccccclollllll    //
//    OOOkkkkkOO00KKK00OxxdxkkOOOOOOOkkkxdollc:;:cccloddxxxxxxxdllcllc:;;;,,'..,;;,'....'',,;;;:;;;;;;::clllooolllc:;,,,''''''',,,:ccloollllllcccccclollllll    //
//    kkkkOO0000OOkxddooodxkOOOOOOOOOkxddollc::clllodddxxxxxxxdollllc:;;;,,,..'::;;'....'',;;::::::::;;;;;;::::;;;;,,,,,,''''',,,,:ccloollllllcccccloollllll    //
//    OOOOOOkkxdooollooodxkOO00000Okxxdoollc:clllooddxxxxxxxxxollolc:;;,,,,'..,c::,....'',,;;::cccc::::::;;;;;;;;;;,;;;,,''''',,,,;:cloollllllcccccloollllll    //
//    OkxdoooollllloooddxkO000000Okxddoollcclooooddxxxxxxxxxxdooolc:;;,,,,'..':c:;,...''',,;;::ccccccc::::::;;;;;;;;;;;,,,'''',,,,;:cloollllllccclloooooolll    //
//    ooollllllllloooodxO00KKK0OOkxddooolllooooddxxxxxxxxxxxdooll::;,,,,''..':lc;'....'',,;;::cccllcccccc::::::::::::;;,,,''',,,,,;;:cloollllllcccloooooooll    //
//    lllllllllloooodxO0KKKK00Okxdddooolloddodxxxxxxkkkxkkxdollc:;;,,,''...,:lc,'...'',,,;;;::ccllllllccccccc:::::::::;;,,,',,,,,,;;::loollllllcclloooooooll    //
//    lllllllllloodxO0KKKK00Okxddddoooloodddddxxkkkkkkkkkxdollc:;,,'''....;cl:,'''''',,,;;;:::ccllllllllccccccccccc:::;;,,,,,,,,;;;;;:cloollllllllloooooolll    //
//    llllllloodxO00KKKK00Okxdddddoooodddddddxxkkkkkkkkkxdlllc;,,'......':ll;''''',,,,,;;;::::ccllllllllllcccccccccc::;;;,,,,,,,,,;;;;:cloollllllloodooollll    //
//    llllodxkO0KKKKKK00Okxdddddoooodxxddddxxxkkkkkkkkkxolccc;,,''''''',:ol;,,,,,,,,,;;;:::::ccclllloolllllllccccccc::;;;;,,,,,,,,,;;;:::loolllllooodoooolll    //
//    oddkO0KKKKKKK00Okkxdddddodddxxxdddddxxxxkkkkkkkkxolcc:;,,,'',,',;ldl:,,,,,,,,;;;::::::cccclllooooolllllllllccc:::;;;;,,,,,,,,,;;;;::cooollllooooooolll    //
//    kO0KKKKKKK00OOkxxdddooddddxxdddddddxxxxkkkkkkkkxolc:::,,,,,,,;;coxo:;,,,;;;;;:::::::cccccclllooooooolllllllccc:::::;;;;,,,,,,,,,,;;;:clooolloddooooool    //
//    0KKKKK00OOkkxdddoooooddddddddddddxxxxxkkkkkkkxdolc::::;;;;;;;:lddl::;;:::::::::ccccccccclllllooooooooollllllccc:::::::;;;,,,,,,,,;;;;:cloooooddddooooo    //
//    KK000Okkxxddooooooodddoooodddddxxxxxkkkkkkkkxollc:::::;;;:::codoc:::::::ccc:cccccccccccllllllooooooooooolllllccc:::::::;;;;;;,,,;;;;;;;:cloddddxxddooo    //
//    0Okkxxddoooollllooooooodddddddxxxxxxkkkkkkxdolc::::c:::::::lddlcccccccllllllllllllllllllllloddoooooooolllllodoccc:::::::::::;;;:::;;;;;;;:codddxxxxxdd    //
//    xxdoolllllllllllllooodddddddxxxxkkkkkkkkxdollc::::cc:::::cldolccccllllooooooooooooooooooolldkxdddddoooooollodolllcccccccccc::::cl:;;;;;::;:clodxxxxxxx    //
//    ollcccccccclllloooooddddddxxxxkkkkkkkkxdollc::::ccc::::ccodolcccllllllooooddddddddxxxxxxddodddddxxxxxxxdddoooooollllllllccccc::cllc:;;::::::cclodxxxxk    //
//    ccccccclllllooooooddddxxxxkkkkkkkkkxxdollc:::::ccc::cccldddollllllllllloooooodddddxxxxxxxxxxxxxxxxxkkxxxddddddoooooollllllccccccccllcc::::::cclllodxxx    //
//    ccclllllllooooodddxxxkkkkkkOOkkkxxdoolcc::::ccccccccllodxdooolllllllloooooooodddddxxxxxxkkkkkkkkkkkkxxxxxxxxdddddoooooooolllllllcccclllllccccccllloodd    //
//    llllloooooooddxxkkkOOO00OOOOkxxdoolcc::::cccccllllllodxxdddooooooooooooooodddddddxxxxxxkkkkkkkkkkkkkxxxkkkxxxxddddddoooooooooolllcccccclllollllllllooo    //
//    loooooooddxxkkO000KKK000Okxxdoollcc:::ccccllllllllodxxxddddddddooooodddddddddddxxxxxxxkkkkkkkOOOOOOOkkkkkkkkxxxxxddddddddddooooolllcccccccllooooollooo    //
//    oooddddxkOO0KKKKKK000Okkxdolllccccc:ccclllllllllodkkkkxddddddddddddddddddddddxxxxxxxkkkkkkkkOOOOOOOOOOOkkkkkkkxxxxxxxddddxxdooooolllllccccccclodddoooo    //
//    ddxxxkO0KKXKKK00OOkkxdoolllcccccccccclllllllloodkOOkxxdddddddddddddddddddxxkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOkkkkkkxxxxxdddddxxdddooollllllllcccclloodddd    //
//    xkkO0KKKKK00OOkkxxdoolllcccccccccccllllllooodxkO0OkxxddddddddddddddddxxxkO0000KK00OOkkkkkkOOOOOOOO00OOOOOOOkkkkkxxxddddddddxkxddooollllllllllllloooodx    //
//    0KKXKK000OOkxxddoollllccclllcccccllllllooodxO000OkxdddddddddddxxxddxxxkO0KXXXXXKK00OOOOkkkkOOOOOO0000OOOOOOOOkkxxxxdddddddddxkxddooollllloooooloooddoo    //
//    KKKK00OkkxddooollllllllllllllllllllooooodxO000OkxddddddddddxxxxxxxxxkO000KXXXXK0OOOOOOOkkkkkOOOOOO000OOOOOOOkkkxxxxxdddddddddxkxdddooooooooooooooddddd    //
//    000OkxddoooolllllllllllllllllllloooooodkO000OkxddddddddxxxxxxkkOOOkO0000KKKXXKKKOOOkkxddddxxkOOOOO00OOOOOOOOkkkkxxxxxxxxddddddxkkxdddooooooooddddddddd    //
//    OOkddooooooooooollllllllllllooooooodxk0KK0kxxdddddddxxxxxxxkkO00000KKKKKKKKK00KK0OkdddddxxxkkOOOOOOOOOOOOOOOOOkxxxxxxxxxddddddddxkxxddddooooooddddddxx    //
//    xxdddddooooooollllllllllooooooooddxk0KK0kxxxddddddxxxxxxxkkkOO000KXXNXXXXK00000KKOxoddxxkkkOOOOOOOO00OOOOOOOkxxxxxxxxxxxxdddddddddxxxxxxdddddoodddddxx    //
//    ddddooooooooooooooooooooooooodddxO0KK0kxxddddddddxxxxxkkkkkOOOOO0XNNNNXXK0000000OxdddxxkkkOOOOOOOO0000OOOOOOkkxxdxxxkxxxxxddddddddddddxxxxxxdddddddddx    //
//    ooooooooooooooooooooooddddddddkO0K0OkxxddddddddddxxxkkkkkkkOOOO0KXNNNXKK000K00OxdoddxkkkkOOOOOOOOOO000OOOOOOOOkkkxkkkxxxxxddddddddddddddxxxxxxdddddddd    //
//    ooooooooooooddddddddddddddxxk0KK0OkxxddddddddddddxxkkkkkkkkOOO00KKXXK0KKKK0OkxdooddxxkkkOOOOOOOOOOOO0000OOOOOOOkkkkkkxxxxxxxxddxxddddddxxxxxkkxxxddddd    //
//    oodddddddddddddddxxxxxxxxk0KKK0OkxxddddddddddddddxxxO00OOOO0000KKKK0OO0KKKOxdoddddxxxkkkOOOOOOOOOOOO00000OOOOOOOkkkkkkkkkkkkxxxxxxxddddddddddxxddddddd    //
//    ddddddddddxxxxxxxxxxxkkO0KK0OkxxxddddddddddddddddxxxO0000KXXKKKKKK0OkkO000OxddddxxxxxkOOOOOOOOOOOOOO000OOOOOOOOOOkkxxkkkkkkkkkxxxxxxdddddddddddddddddd    //
//    dxxxxkkkkkkkkkkOOO0000000OkxxdddddddddddddddddddxxxxO0KKKXXXXXXK000OOkOOO00OkddxxxxxxkOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkxxxkkkkkkkkxxxxxxxdddddddddddddddd    //
//    loodxxkkkOOO00KXXXXK0OkxxxxdddddddddxddddddddddxxxxxO0KKKXNNNXXXK00OOOkOOO00OxxxxxkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkxxxxxxdddddddddddddddo    //
//    ;;::clodxxkkkkOOkkkxxxxxxxddddddddxxxxxxxxxxxxxxxxxxOKKKKXNNNNNXKKK00OOkOOOOOkxxxxkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO000Okxkkkkkkxxxxxxdddddddddddddol    //
//    ;;;;:::ldxxkkkkxxxxxxxxxxxddddddddxxxxxxxxxxxxxxxxxkOKKKKXNNNNNXKKKKK0OkkkkOkkkxxkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00000Oxdxkkkkkxxxxxxdxxdddddddddol    //
//    ;;::::::ldxxkkkkxxxxxxxxxxddxxddddxxxxxxxxxxxxxxxxxkOKKKKXNNNNNNKKKKK0OkkkxxxkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00K000kddxkkkkxxxxxxdxxxdddddxddol    //
//    ;::::::::ldxxkkkkxxxxxxxxxxddxxxdddxxxxxxxxxxxxxxxxk0KKKKXNNWWNXKKKKK0kdxxxxxkxkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOO00O00KKK00kxdoddxxxxxdxxxxdxxdddxxdddo    //
//    ::::::::cldxxkkkkkxxxxxxxxxxddxxddddxxxxxxxxxxxxxxxk0KKKKXNNWWNXKKKKK0xddxxxkkkkkkOOkkOOOOOOOOOOOOOOOOOOOOOOOOOO00O00KKK00kxddoolodxddxxxxxxxxxdxxxxdd    //
//    :cccccclooddxkkkkkkxxxxxxxxxdddxxdddxxxxxxxxxxxxxxxk0KKKKXNNNNNXKKKKK0xddxkkkkkkkkOOkkOOOOOOOOOOOOOOOOOOOOOOOOOO00O00KKK00kxxddoolodddxxxxxxxxxxxxxxxx    //
//    cccllccoxxddxxkkkkkkxxxxxxxxxddxxdddxxxxxxxxxxxxxxxO00KKKXNNNNXKKKKKK0kddxkkkkkkkkOOkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0KKKK0Okxxxdooloddddxxxxxxxxxxxxxxx    //
//    lclolccokkxxxkkkkkkkkxxxxxxxxxddxxxxxxxxxxxxxxxxxxxO00KKKXNNXXXKKKKKKOxdxxxkxkkkkkOOkkOOOOOOOOOOOOOOOOOOOOOOOOOOO000KKKK0Okkkxxdolodxdxxxxxxxxxxxxxxxx    //
//    lloolccdOkkkkkkkkkkkkxxxxxxxxxddxxxxxxxxxxxxxxxxxxxO000KKXNNXXKKKKKK0kddxxxxkkkkkkOOkkOOOOOOOOOOOOOOOOOOOOOOOOOOO00KKKKK0Okkxkkxoooxxxxxxxxxxxxxxxxxxx    //
//    lodolcokOOkkOOOkkkkkkkxxxxxxxxdddxxxxxxxxxxxxxxxxxk                                                                                                       //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PNGPSD is ERC721Creator {
    constructor() ERC721Creator("Fantasy Women Portraits", "PNGPSD") {}
}