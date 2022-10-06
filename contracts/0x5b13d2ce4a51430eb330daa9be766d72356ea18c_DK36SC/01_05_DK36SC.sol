// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Systematic Chaos
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//    ......................................................................................................................................................    //
//    .....https://www.instagram.com/deniskershner336/......................................................................................................    //
//    ......................................................................................................................................................    //
//    ......................................................................................................................................................    //
//    ......................................................................................................................................................    //
//    ....................................................';ccllcclc:;,,'',;;,'.............................................................................    //
//    ................................................':lcclllcclodddxdoodxdolll:;,'........................................................................    //
//    ......https://twitter.com/36Denny_K...........,:c:,....,cokO0OO00KKXNNXK00kkxdo;......................................................................    //
//    ............................................';;...',cdk0KXXXXXXXKXNNWWWWNXXKK0Od:,...''''''''''.......................................................    //
//    ...........................................'...'cx0XNWWWWWNNXXXK00KXNNWWWWWWWNKOkxollllodollooodol:,'.................................................    //
//    .............................................,o0NWWWWWWWWWWNXKKOkxkOKXWMMMMMMMWNNKOkddxkkkxkO0KKXKKK0ko,..............................................    //
//    ........................................,..;dKWWNNNNNWNNNWWWWNNXXKXXNWWWMMMMMMWWWNXKYIVKXXXXNWWMWWWWWWNKx:............................................    //
//    ......................................,:'.lKWWWNNNWNNXNWWWWWWWWWWWWNXXXXXKKXXXNNNNNNWWWWWWMMMMMMMMMMWWWWWXx:'.........................................    //
//    .....................................;c;cONMWWWWWNXXNWWWWWWNNNNNWNXKOkxxxdddxOXNNNWWWWWWWMMMMBTCMMMMMMMMMWWXOl'.......................................    //
//    ....................................;olxNMMWWWWNXKXWWWWWWMWWWNNXKK0OOkkdlc:;:lxO0KKKK00KXNNWMMMMAXIMMMMMMMWWWNk,......................................    //
//    ....................................xKXWMMMMMWXKXWWWWWWWWWMMMMMWNXK0Oxdoc:,'',:odxxdlcoxxk0KXXXWMMMMMMMMMMMMMMWO;.....................................    //
//    ...................................cXMWMMMMMWXXNNXXXXXNNWWWWMMWNNNX0kdl:,'....':odxdodkkxk00KXNWWWWMMMMMMMMMMMMWKc....................................    //
//    ..................................;0WMMMMMMWXKXK00KXNWWWWWWNNXK0Okxdc;'........;:c:;;::;:c:clx0XWMMMMMMMMMMMMMMWW0l...................................    //
//    .................................,kWMMMMMMWXKXX00XNWWWWWNKOxoc;;,,'..........................';lkXWMMMMMMMMWWWWWWN0d'.................................    //
//    ................................;OWMMMMMMWXKXN0OKWWWNK0ko:'.....................................,lkXWMMMMMMMWNNNNWX0x,................................    //
//    ...............................,kWMMMMMMMNKXN0kONWNKkoc,.........................................,lkKNMMMMMMNXNXXWWX0d'...............................    //
//    ...............................dNMMMMMMMWKKXXOOXNXOdc,...........................................':ox0NWWWMMWKKXXNWNX0l...............................    //
//    ..............................cXMMMMMMMWX0KNKOXWKko:'.............................................,ldk0NWWMMNKXXKNWWNKOc..............................    //
//    .............................lKWMMMMMMMWKKXXK0NX0dc,..............................................';lxOKNWMWXKNNKXWMNXKk:.............................    //
//    ............................cXMMMMMMMMMNKXNXKXNXOo:'...............................................';lx0XWWXKXWWXXWMWNK0x;............................    //
//    ...........................cKWMMMMMMMMWKXWNNXNWXOo:'................................................';dOKNX0KNWWXXWMMN000o'...........................    //
//    ..........................:0WMMMMMMMMMNKNNNNXNWXOdc;'................................................'cx0KOOXMWWNNWWMWKOOkc'..........................    //
//    .........................;OWMMMMMMMMMWXXNNNWNWWXOxoc;'................................................,oO0ddXMWWWNNWMMXOkkdl'.........................    //
//    .........................oXWMMMMPAINTINGWNNWWWWN0kdl:'.................................................ckOlcOWWWMWNWMMN0kkxdl'........................    //
//    ........................,dXMMMMMMMMMMWWWNXXWMMWNX0koc,.................................................;dOl,oXWWMWWWMMWKOOkxxl'.......................    //
//    ........................'dNMMMMMMMMMMMMWNXNWMMWNXKOdc;,'..............................................';oOl,:xXWMMWWWMN0kkOOOxl,......................    //
//    ........................;OWMMMMMMMMMMMMWXXNMMMWWNXKOkkkxddddoooollllc:;,....'.........'',;cllc:cl:,'..;lk0d,,ckNMMMWMMN0kkOO00ko:'....................    //
//    ......................'.cXMWMMMMMDDRAWINGNXXWMMMWWNNWNXK0OO0KKK0000OOxddlc:::,........,:ldkO00OOxl;...'ckKk:,;lOWMMMMMNKkkOkk0K0kl,...................    //
//    .....................'..xWMMMMMMMMMMWNNXXNWMMWWWWWWWNK0kxkkO0KKK0000OkxxOOxdl,........';okOKXNNXKOdoc;,,oK0l';coKMMMMWNKOOKKOkOKKOd;..................    //
//    .....................'.;KWWMMMMMMMMMWNNXXWWMMWWWWWWNKOOKXNWWWXxl;;codxO0KKOxl'.........;lolx0XNOc:,'cddloOkc'':lOWMMMMNK0O0KKK0000Oxl'................    //
//    ....................'..lXMMMMMMMMMMWNNWWWMMMMWNWWWNKKKKOkOOO0d'.....';lkKX0ko'..........,,,,;:l:.....,::lxd:'.'cOWMMMWNK0kOKKKXKOkkOOx:...............    //
//    ...................''..lXMMMMMMMMMMWWWWMMMMMWWNWWNNXNNKd:,'''.........'lOKOko'...........','............'ldc...;xNWWMWX000KKKXNXKOkkxOkl'.............    //
//    ...................'...lXMMMMSCREENWRITTINGMMMWNNXXNNNXOdc,...........,dOkdoc'............''.............,do'...c0WWWNK00KXNXKNNNX0OkoxOd'............    //
//    ......................'oXMMMMMMMMMMMMMMMMMMWWNNXKK0KKK00ko:,..........:ddoc::,............................cl'...;OWWXXKO0KNWWXXNWNX00d:o0d'...........    //
//    ......................;kNMMMMMMMMMMMMMMMMMMWNXX0Okddooool:,'.........,:llc::;,............................,c,..':kNWNXK0XNNWMWXNWWNXKO;'dOl...........    //
//    ..................'...cKWMMMMMMMMMMMMMMMMMMWNXKOxoc;,,,''............,:llc:::,............................'c,..,cOXNNXANARCHYWNNNWWNXXd.:Ok:..........    //
//    ..................,,..o00XMMMMMMMMMMMMMMMMMWNXKOdc;'.................,coolc::,............................'do...'l0NXXXNWMMWWWWNNWWNNNk'.dOo'.........    //
//    ................,:c;.;kl:OMMWMMMMMMMMMMMMMWNNNKOdc,..................;oxxo::;'.............................oO:...:ONNNNWMMMWWWMWNWMWXN0:.cdo;.........    //
//    ................:k0xdkd'.kWMMMMMMMMMMMMMMMWNNNK0xl;'................'ck0x:''...............................:x:.,cxXNNWNNWMMMWWMWNWMWNN0c.:xxc.........    //
//    .................;odd:;'.oNMMMMMMMMMMMMMMMWNNNX0xl:,................;dOxc;'................................,xc...:OKXWNXWMMWWWWWWWMWWXOc.:00c.........    //
//    '...................';::.,kWMMMMMMMMWWMMMMWNNXK0xo:;'..............'ckxlclcc;'.............................'dc....dKXNXXWMMMWWWWWWMWW0o:'lN0,.........    //
//    '''...................;locl0WMMMMMMMWWWMMMWWNXK0koc:,'............';lxOkOKXX0o;............................'o:...'d0KXXXWWWWWWWWWWWMXooc;kNl..........    //
//    ,''''''''..............';cxKWMMMMMMMMWMMMMMWNXK0kdoc:,'...........,;cd0NNWMMWXkc;;,'.......................'l;....d0KXXNWWWWWWWNWWMNxcddkKo...........    //
//    ,,,,'''''''...............lXWNNWMWX00NMMMMMMWXK0kxolc;,'.........',:lx0NWWMMWWXOo:,........................,c'...'dKXXNWWMWWWNXNWWWOcd0X0l............    //
//    ;,,,,,,'''''..............oNWKOKWWNkldXMMMMWWX0Okxolc:;'.........,:ldOKNWMWWNXOo;,,'.'',,,.................;;....'dKNWWWWWWWNKXWWW0dkXXx;.............    //
//    ;;,,,,,,,'''''''..........:0WKldNWWWK0NMMMMWXKOkxdolc:;,'.....';cok0KXNWNXKKOo;'.......',;::,,,,..........;;.....,xXNWWNXNWNXXWMWN000k:...............    //
//    ;;;;;;,,,,,,'''''''''......:O0kONN0OXWMWMMMWXOOkxdolc:;,'....:dO0XNNXXXKK0kxo:'...........',,;:c;,.......;:......:ONNWNXNWNXNWWNX0xc'.................    //
//    ;;;;;;;;;,,,,'''''''''''''..,cddkXXOOXNNWWWWKOkkkdoolc:,'..'ckXXXNNNX000000Okdoc;'............,;:;'....':;......'dXWWWWWWWWWWXOdc'....................    //
//    :::;;;;;;;;,,,,,'''''''''.'''...'oKXKkd0NKNWNKOkkkxollc:,',;o0NWNXXXXXXNNNXXK0Oxoc:;;,,,,;;,''',,,....,:,.......oXWWMWWWWNXOdl;.......................    //
//    :::::;;;;;;;,,,,,,,,'''''''.''.'.';oxdxKNKXWNKOkxxxddolc;,,;lkKKOxxOXNNXKOxdoc;,'.........''.......',;,.......,oKNWMWN0kdl;'..........................    //
//    cc::::::;;;;;;;;,,,,,,'''''''''''''',cdONWNNNKkollloddoc:;,,:lllc::lodxdoc;,'....................';;'........';lONMMWNXko:,...........................    //
//    cccc::::::;;;;;;,,,,,,,,,'''''''''''',':ONKKWN0dc::ccoollc::;;;;;;;::clllc:;,''',,,,..........................,lONMMMMMMWNKxc,........................    //
//    ccccc::::::;;;;;;;;;,,,,,,''''''''''''',dXKKWWN0xc;;;:clllcc:;,;;:;;::cllooll::cllc;'........................,lddONMMWMMMWNKOo:,'.....................    //
//    llccccc::::::;;;;;;;;,,,,,,'''''''''''''c0NNWMWWXkc;;;:ccclllc::cc:::ccloodddoooxxl:,.......................:d0Oc;kNWMMMWWX0xc,.......................    //
//    lllllcccc::::::;;;;;;;;,,,,,,,,,,'''''',ckNWWMMMWXOxocccccoddolccc::::::::cllodxkkxo;.....................'cx0XKx;;xXWMMWX0Oxc,.......................    //
//    ooollllcccccc::::::;;;;;;;,,,,,,,,''',,,:o0XNKKNWWNNKkxdlloxkkdlc::;,,,''.''',cdkxol;...................';lxKNNNXo',oOXWWN0d:,'.......................    //
//    oooollllllccccc::::::;;;;;;,,,,,,,,,,,,,;;:lxdoxXWWMWNX0Oxddxkkxdol:;,'.......';cccc;'...........,:;,',;lddxXWMMWXdcccdO0Ox:'........''''''''''''''''.    //
//    dddoollllccccc::::::::;::;;;;;;;;,,,,,,,,,,,;:cco0NMMWXXK0OOO0KK0OOkdolc:,'''',;:loolc:;;,'',,,:loxkxddxxl,lXNNWMWNXOxo:;,'''.'''''''''''''''',,,,,,,'    //
//    kkkkkkkkxxxxxxddooolllcc::;;;,,,,,,,,,''',,,,',,,cdOXKdxKXKXNNNNNNNNXKKOdcclooooxkOkxkkdolccccoxkOKXKK0kc..lXKkkO0Okoc;''''''''''''''''',,,,,,,,,,;,;,    //
//    ccccccccccccllooooooodddoograffitioo:cccllllllllcccok0x,,dKNMMMMMMMMMMMMMWWNNXXNNNWWNNNNNNXXNNNWMMMMWXx,...;occlcccccccccllllllloooooodddddxxxxxkkkkOx    //
//    c::::;;;;;;;;;,,,,,,,,'''''''''......................,:,..:xXWMMMMMMMMMMMMWWWNNNWWWMMMWWWWWWMMWMMMWXkc'.....o0KXNNNNNNNNNNNNNNNNNNNNNNNWWWWWWWWWWWWWWK    //
//    cc::::;;;;;;;;;,,,,,,,'''''''''.......................'....'oKWWMMMMPLUTUSMMWWWWMMMMMMMMMMMMMMMMWW0c.........:dOXWMMMMMMMMMMMSTREETARTMMMMMMMMMMXxXXXX    //
//    cc::::;;;;;;;;;;,,,,,''''''''''.............................,xKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0l'...........';ckXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX    //
//    ccc::::;;;;;;;;;,,,,,,'''''''''..............................:dOKNWMMMMMMMMMMMMMMMMMMMMMMMMWKkl;'..............',,lKWWWWWMMMMWWWWWMMMMMWWMMMMMMMMWWMMX    //
//    cccc:::::;;;;;;;;;,,,,,,'''''''''''..........................':okKXNWWMMMMMMMMMMMMMMMMMWNK0d;...................,cdKWWNOolodOKXNNNNNNNFORTUNANNNNNNWWW    //
//    ccccccc::::;;;;;;;;,,,,,,''''''''''''''.......................,cdOKXNNNWWWWWWWWNXK0OOkxo:;'.....................cONWMWWKc'..';oOKXXXNNXNNNNNNNNNNNNNWK    //
//    ccccccc:::::;;;;;;;;,,,,,,,,,'''''''''''.......................;lxOKKKKXKKKKKK0kxol:;,'........................l0WMMWWWKc.'....;lxO0KXXXNXNNNNNNNNNNWK    //
//    lccccccc:::::;;;;;;;;;;,,,,,,,,'''''''''''''''''''.,c:.........':oxOOOOOOkkkxxdol:;,,''......................:xXWMMMWWKl.........',cxO00xxkxdoolllloxd    //
//    c:::::::;;;;;;;,,,,,,,,,''''''''''''''.............,l:..........,:ldartdollllcc:;,,'........................lOXKKKXXKk:.....,;,....,oxkxooo;.   .  ...    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DK36SC is ERC721Creator {
    constructor() ERC721Creator("Systematic Chaos", "DK36SC") {}
}