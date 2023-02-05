// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JackPassBurn
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                   //
//                                                                                                                                   //
//    kOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxxdlc;;;,;:clxkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxxdllc::;,'''....',:ldkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxoc;,,,;;::::;;;;;,,'''...,:oxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOko:,,;::c:cc:::;,,;;;;;;;;,,,;:cdOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdllodddoooolllc:;;;:;;;;:cllccoxkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxkkkkkkkxxxxdddolcccc:::cllooolldkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxkkOOkkkkOOkkxxxddoooolloodddddooooxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxxxxkkkkkkO0OkkxxxxxxxxxxxxxxxxxddddooxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxddxxxxkkkkOOOkxxxxxkkkkkkkxxxxxxxdddddoxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkddddxxxxxxkkkkxxxxkkkkkkkkkkxxxxxxddddddoxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxdddddxxxxxkkkkkxxxkkkkkkkkkkxxxxxxdddddddodOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOdoodddddxxxkkkkkkkkkkkkkkkkkkxxxxxxxxxxxddddxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdoooodddxxxkkkkkkkkkkkkkkkkkxxkkkxxxxxxxdddddxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxllooodddxxxkkkkkkkkxkkkkkkkkkxxkkkkxxxddddxxddkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkc;lllooddxxxxxxxxxxxxxxkkkkkkkxxxxxxxxxxxxxdddddkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOx''cllooddxxxkkxxxxxxxxxkkkkkxxxxxkkkkkkxxxdddddddkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOd..:lloddddxxxxxxxxkkkkkkkkkkkkxkkkkkkkkxxddoooooodkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOd'.,lloddddxxxxxxxxxxddxxxxkkkkkkkOOOOkxxdooloodoooxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOx,.'cooodddxxxxxxxxxxxxdoooodxkkkkO00kxooodddddddoodkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOk;.'coooodddxxxxxkkkkkxxxddooodxkkO0Okdodxxxkkdc::clxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOd,.'coooodddddddxxkkOOxooddxxxkkkkkxxxxkxxkOOx,  .,:dOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxddl,.,codoodddddoodkOOkc'...'lddxxxxxxdddddxkkko.   .:dOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkolccl:';odoooddddolloxkko.    .;ooddddddddoooddxdo:'..,cxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdlllll;':dddoooddddoloddxdc'..',cooddooddoooddddoolc:;;;cxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkollloo:,lddddddddddddolooooollooooodooodddddooodoolc::;';xOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdlooooc:loddddddddoooooooooooooooodollodddxddooolc::;,,,cxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxoloooolllodddxxxxddooolllllooddxdooloooddxdddoolcllc:;:oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxoooooolclloddxxxxxxdddddddxxxxxooloooooooooolc::loll:lkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxdddolllollloodddxxxxxxxxxxxxdoc:;:cllllcc:;,'';cccccdOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdollooolloddddxxxxxxddooooolc;,,,,,,,,'....,;:;;;oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkxdoooodddddxddddddddoollloolllllllc::;;,,,;;;:;;,,lkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO000kolooddooodddxxdddooolllllllllllllllllllclllc::::;;,,':xOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOO00KKKkoloddddooooddoollllcccccclllllllloolllcclllc:::;;;,'.;xOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOO0KXXKOxdxxxxddoooooolcccccccccccclllllooollllccclllc:;;;,'.,oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOO0KXXKOdldkxddxddddolcccc:::::cccccccccllllllllccccllc::;;,'';dOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOO0KXXX0xoxOkxxdxxxddolc::;,,;;::cccccccclllllllllcccllc;,,,...';ldxkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOO00KXX0xxOOOkxdxxxdddl:;:::;;,,,,,,,;;;;;;;;;;;;;;;;;,'........',;cloxkkOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOO00000OO0KXKOkOOOkxxxxxdddoc;;:ccccc:;;;;;;;;,,,,,''''''''.......''.',,;codxxxkOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOO0000KKKKKK0OkO0KXK0OOkkxxxxxddxol:;,,,;;;;;:::::::ccc::;;;;,,,''',,''.''.',,;:loxxxxkOOOkkOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOO0000KKKXXXXKKK0OkkkO0KXK0Okxxxxxxdoddoc:;,''.....'',,;;;::::::;;;,,,'''....'..',;:clodxxxxOOOkdxkkOOOOOOOOOOOOOOOO    //
//    OOOOO000KKKKXXKKKKKKK000OOkkkO0KKXKOkddxxxxddddlc:;;;,,;;,''.......................''..';cclodddxxxkO0OxddxkkkkOOOOOOOOOOOO    //
//    O0000KKKKKKKKKXXKKKK00000OOkkkO00KXK0kddxxxxdoddoc:;;;;;;;;::;;,..................''..';looloxxddxxkOO0kdodxxxxxkkOOOOOOOOO    //
//    OKKKKK00000KKXXKKKKK000000OOOkOOO0KXXKOddxkxxdodddl:;;;;;;;;;;;;;;;;;;,,''''''..'''...,cdxxoddxddddxkO0OkoodxxxxxdxkOOOOOOO    //
//    O0000000000O00KKKKKK00O00000OOOOO00KKXK0kddxxkxooddoc;;;;;;;;;;:cccccc:::;;;;,,',,...'cxOOkdodxxdodxkOOOOxoodxkkxdodxkOOOOO    //
//    0KKKKK0000000000KKKKK0OO00000OOOOO00KKXXK0kxdxkkxooool:;,,,,;;;:::::;;,,,,,,,,,,,'...:dO00OxdddddooxkkOOOkoodxxkkxdodxxxOOO    //
//    0KKK000000000000000000OOO00000OOOOO00KKKXXKOxddxkkxdool:;;,,,,,,,,,,'''''',,,;;,'..'cxO0000OxddddoodkkOOOkxoodxkkkxdodxdxkO    //
//    OKKK0000000000000000000OkO000000OOOOO0KKXXKK0kddxxkkkxdoc:;;;,,,,,,,,,,,,;;;;;,'..;okO0K0000OxdddoodxkOOOkkdodxkkkxxdodxddx    //
//    O0000000000000000000000Okk000000OOOOO00KKXKKKKOxdodxxxkkxdl:;;,,,,,,,,;;;;:;;,...cxO00000OxxxxxdooodxkkOOOkdooxkkkkkxdoddoo    //
//    O00000000000000000000000OkkO0000OOOOOO00KXKKKKK0Oxdodddxxxxdolc:;;,,,;;;;:;;'. .ck0000000kc'..';clooxkkOOkkxoodxkkkkxdoodol    //
//    O0000000000000000000O0000kxk00000OOOOOO0KKXXKKK0000kdooodddddddol::;;;;;;;;'...lO00000000Od'    .;loxkkkOkkxoldxkkkkkdlcool    //
//    O000000000000000000OOO00OOddOO0000OOOOOO0KKKOd:,cOK0Okxddooooooollcc::::::;,';oO0000000Oxl:,... ..:ldkkkOkkxdloxkkkkxoc:clc    //
//    O00000000000000000000OOOOOkodOOOO00OOOOO00kl'...:oxkOOOOkxxxxxxddddddooooooooxO000000kdc;;:cllc:,';coxkOkkkxdlldxkkkxl::ccc    //
//    k0OOOOOO00000000000000OOOOOxldOOOO0OOOkOkl,..;oOx,..';ldkOkkkxkkxxxxxxxxxxxxkO00000ko:,,;;;:ldkxdllccokkkkkxdlloxxxxdl:cccl    //
//    O00OOOOOOOOO000000000000OOOOxldOOOOOOOkx;..':dkOOdc;'....:oxxkkxxxxxkkkkxxxkO0000ko;';clllodxkkkxdxdlldkkkkxdlcldxxxdl:::co    //
//    O000OOOOOOOOOO00000000000000OdldOOOOOOd:..'codxkOO00Okdl;,;:ccldxxxxxkkxxxkO000ko;,;ldddodxkkkkkxxxxxdxkkkkxdlllodxxdl;;:lo    //
//    O00000OOOOOOOOOOO0000000OO0O0OdldOOOkd;',cdkkxdxxkOO0000OkxdollllodxxxxxxxkO0Oo:,:okkxdddxxkkkkkxxxxkkkkkkxxdolloddddl;;coo    //
//    O00000OOOOOOOOOOOOOO00OOOOOOO0Oocdkko,':dOOOOkkxxxkkkOOOOOOO00OOkxxdxxdddkOOd:,:okOkxdddxxkkkkkkxxxxkkkkkkxxdollodddoc;;coo    //
//    O000000OOOOOOOOOOOOOO0OOOOOOOOOklcoc,,lkOOOOOOOkkxxxxkkkOOOOOOO000OkkxddkOxl;:okOOkxxxxxxkkkkkkkxxxxxkkkkxxddllloddol:,;coo    //
//    O0000000OOOOOOOOOOOOOOOOOOOOOOOOxc',cxOOOOO00OOOOkkxxxxkkkOOOOOOOOOOOkkkxo::okOOkkkxxxxkkkkkkkkxxxxxxxkkxxxdolllooooc;,,:lo    //
//    k00000000OOOOOOOOOOOOOOOOOOOOOOOOxodkOOOO000000OOOkkkkkkkkkkOOOOOOO0OOkdccoxOOkkkkkkkkkkkkkkkkkxxxxxxxxxxxxdoolooool:,,,;lo    //
//    xOO000000OOOOkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkOOOOOkdodkOkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxddoolooolc;',,;lo    //
//    oxkOO000OOOOkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkxxOOOOkkOOOkkkkkkkkkkkkkkkkxxxxxxxxxxddooooooc;'''';co    //
//    :oxkOO00OOOOkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkxxkkkkkkkkkkkkkkkkOOkkkkkkkkkxxxxxxxxxdddoooollc,'''';lo    //
//    ,:odxkOOOOOOkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkxxkkkkkkkkkkkkOOOOkkkkkkkkkkkxxxxxxxxddddooooll:,'''';lo    //
//    ',:ldxkkOOOOOkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkOkkkkkkxkkkkkkkkkkkkOkkkkkkkkkkkxxxxxxxxxxxddddoooollc:,'.';cc    //
//    ',,:ldxxkkkOOkkkkkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkOkxxxxxxxkkOOkkkkkkkOOkkkkkkkkxxxxxxxxdddooooolllc;'.';::    //
//                                                                                                                                   //
//                                                                                                                                   //
//                                                                                                                                   //
//                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JPB is ERC1155Creator {
    constructor() ERC1155Creator("JackPassBurn", "JPB") {}
}