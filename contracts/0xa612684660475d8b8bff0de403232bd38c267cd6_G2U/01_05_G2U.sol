// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Glory to Ukraine
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    kkkkkkkkkkkkkkkkkxo:;'':oxxc,,,''.';l:'.';;::c::;,;::cdkOOOxl;;;;cdkxlccx0000000000000000000000xollccldkOkkkOOkdoldkkkdlcoolc;;;,;odddddddolcccloxxxxx    //
//    kxkkxxxxxxxxxxxxxo:,'.':oxl'...''..,:,...',::;,;;,''''':lodlc:;;;:ldkxooxOOOOkkkxxxxxxxkkkkkkkxdoooc:ldooxkkkOkxdooxkkkdloddolldoccdddddo:;;,.,:;:ldxx    //
//    kkkxxxxxxxxxxxxxdl;'..,cdd;...'''.',;'...';cc;',;:;;,;;:ldxxdlcc:::cllc:cloooddxxxkkkOOOOOOOOOOOOkd::ldl;ckkkOkkxxddxkkxdddlcloOKxlodddl,;ldl,cxd:,cxx    //
//    kkxxxxxxxxxxxxxxdc,'.':ldc'...,,'..',....':loc;;:;,,;:clodxxxxdoc;'.';ldxkOOO0000OOOOO000000000KK0xdoddl:lkOOOkkkkkxxkkkkxdl;cox0Ooldxd:'lxd:.,odd;;dx    //
//    kkkxxxxxxxxxxxxxl:,..,:oo;...','...''....':odolc:'..;:ldxxkkkkkdc,'',oO000OOOOOOOOOOOOO0000OOOOkkxddddl:cdOOOOkkkkkkkkkkkkko::oxO0xloxdc';:;,.';::,:dx    //
//    kkkxxxxxxxxxxxxdc;,..,cdl,...,,...',;'.'',coddool:,:oxkkkOOOOOOx:,,;;cx000000OOOOO0OOkO00OOkxxxdxxkkkkxdxxdxxkkkkkkkkkkkOOkdc;coxOkoldxdc'.:l,;l;';oxx    //
//    kkkxxkkxxxxxxxxoc;'.',cdc'...'...',;:;,:::lddolloollxkOOOOOOkkxoc::;,;lk00OkkkxkkkkkkkOOOkkOOOOOOO000K000OxooooodddddxxxkOkoc;;lxxo:;lxxxoc::;;:clxxxk    //
//    kkkkkkkxxxxxxxdc,,;:cclc,'cc'...',;:::;colodxoccdocldkkxdoooollloddddxOOOOOOOOOOOkkkkOOOOOOOOOOOOOO00000KK0OOOkxxddoooodxkOdlllkKK0xc:oxxxxxxxxxxxxxkk    //
//    kkkkkkkkkxxxxd:,;loolc;'':xx:...';cll::ldodxxo;:lc,,:cc:cclodxxxO00KK00kxkOOOOOkkkkkkkkkkkOOOOO000000000KK00KKKKK000Okxxddddodk0KKKKx:lxxxxxxkkkkkkkkk    //
//    kkkkkkkkkxxxxxl,;;;;:lo:;lkkc...,:loo:;odxxxo:',,;;clodxxxddxxxddkkkkkkxkO000OOOOOOOOOO0000000000K0000KKKKKKKK000KKKKKK00Okdooddxxxd:;lxxxxxkkkkkkkkkk    //
//    kkkkkkkkxxxxdl:,;clxO0Od:lxko,.',coxo;:oolc:;;:loxkkOkkxxxxxkOOOOOOO00000000000000OOOOOOOOO000000000000000K00OdccdKKKKKKKKKK0Okxdol:;cdxxxxkkkkkkkkkkk    //
//    kkkkkkkkkxxxc'';ccokxlldocokxc,;coxxc;;;;:coxkOOOkkkOOOO0000000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOko;..;kKKKKKKKXXKKKK00Oxlldkkkkkkkkkkkkkkk    //
//    kkkkkkkkkxxxo;',;clddodOk::dkdccllc:;:coxkOOOOOO0000KKKKKKK00000000000OOOOOOOOOOkkkkkxxxxxxxxxxxxxxxxxxxxkxxo:'...l0KKKKKKXXXXXXKKKxldkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkxl,,cdddxkxxdccdkxl:cccoxkkkkkOO00KKKKKKKKKKKKK00000000OOOkkkxxxxddoolllllcccccllooollllloooddooc;''..,xKK00O0XXXXXXXXXOdxkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkxl;cdxoccldkkkkxoodxkOOOOOOO00KKKKKKKKKKKKKK000000OOOkkxxdoollccc::;;;,,,,,,,;;:ccc::;;;:ccllll:,'....cOK0Ok0XXXXXXXXX0xxkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkd:,:cclok00kxxxk000OOkO00KKKKKKOkxO0000000000OOOkxxdoollcc::;;;,,,,,,,,,,,,,;:lodddddddxxkkOkxl:,'...,xK0xokKXXXKKXXKOxxkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkxdolc::ldddk0OxdkO000OkkO00KKKKK0ko:',cxOO000000OOkxdollc:;;;;;;;;,,,;;;;;;:cllodk0KKXXKKKKKKK00Oxdc,,''.'l0OocdKXXXKKKK0kxxkkkkkkkkkkkkkkkk    //
//    kkkkkkkkko:;;:lodxxoodooxO000kxxk0KXXXK00ko:,''',:lok00000Okxdoooddolc:coolllccloooooxO000KXXXKKKKK0000Okdc;,;;,'''.:k0d:o0XXXK000Oxxxkkkkkkkkkkkkkkkk    //
//    kkkkkkkkko::loolldxolcoxOOkxodk0XXXXXX0kxc''',''''';ok00000OOkO00KKKK0OO00000Oxxddoodk0KKKKKKK00OO00O000Odll:,,,'''.,d0xllOXXXX0OOkxdxkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkxlodxxolooloodolllokKXXXXXXXXKd;'.'',,''..'ck0KKKKK000KKKKKKKXXXXXKKK0koc:,,:x0KK0000OxoxK00KXXKOdlol,''...'cOOdokKXXX0kkxddxkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkxxxddxxoodxkkxdkKXXXXXXXXKKXx;.''',,,''.,o0KXK0OOkkOOOOO00KK000KKKK0kdc;'',lk00OOOkd:,:x0KKK0dddlcl:,,''..;xKkxk0OkO0kxoodxkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkk0KKKKKkx0KXXXXXXXK0KKKX0l'..'',,,',lkKKXKK00KKK000K000000OO00K0Oxo:;;;lxOOOOkxol::coddooc:,';lolc;,'.,dK0kxOOdoxkdccoxkkkkkkkkkkkkkkkk    //
//    OkkkkkkkkkkkkkkkOKXXXKOdxOKXXXXXXK00K0KXx;''',,,,:oO00KXXXK0xx000KKXkdxO0OkOO00Okoc:;;cdkOkxddoooollllllc:;,;cllcc;,''l0KOxkK0dxkoccoxkkkkkkkkkkkkkkkk    //
//    OOOOOOOOOkkkkkkkk0XXXKkddk0KXXXXXX0O000K0l''',,;:dO0OOKXKOOd:;lkOOOkdlodxdxkO00Okdl:;;:lldkkxdoddddoolcc::;;::;:::;,'';kXKkxOkk0Oo::ldkkkkkkkkkkkkkkkk    //
//    OOOOOOOOOOOOkkkkxk0XXKkddxOKXXXXXXKkkOO0Kx;''';clx00OOOko::lolllooodxxxddxkO00OOOxoc:;;:;:dkkddooloollcc:::;;;;:cc:,'''oKXOxkOKXko::ldkkkkkkkkkkkkOkkk    //
//    OOOOOOOOOOOOOOkOkdx0KKkdxkOKXXXXXXKkdkkk0Oc'',:ldk000kl,;:oxxxxdddddxxddddkOOOOOOkdoc:;;,':xxdoollllccc:::;;;;:ccc:,'''cOXKO0KXKOoccodkkkkkkkkkkkkkkkk    //
//    OOOOOOOOOOOOOOOOOkddkOxodO0KXX0OO00OooxxkOd,''',;clodxc,;lxkxxdddooddoooodkOOOOOOkxoc:;;;,;oxddoolllllcccc:::ccclc;,''';xKOk0NXKOdoooxkkkkkkkkkkkkkkkk    //
//    OOOOOOOOOOOOOOOOkkkdoxxoldO00kolooooc:ccccc'.....','.;llcoxxdooollooollloxOOO00OOkxol::::::lxxxdoooooollllllllllc:,'''''lOkkKNXKOxdddkkkkkkkkkkkkkkkkk    //
//    OOOOOOOOOOOOOOOkkkkkdodo:;ldxdoxO0Oxo:;,.. .....;oxo'.cdooooooooollllllodkOOO0Okkkxol::::cllloxxxoooooooooddddol:;,''''':k0k0XXKOkdxkkkkkkkkkkkkkkkkkx    //
//    OOOOOOOOOOOOOOOOkkkxocclc;cx0X0O0XKOl'. ..,c:'..':oc.,loooooolllccccllodxxO00Oxddxxoc:;;;cllc;:oxdoooooooodxxxdc;,'''''',dOdxXXKOxxkkkkkkkkkkkkkkkkOko    //
//    OOOOOOOOOOOOOOkkdoooddodxclkOKXKxoc'. ..,ldkx;''.''.'lddddoolccc::cclooddxOK0OxxkOOxolc::lllccccodoooooollcccc:;,,'''''',okod0KOkkkkkkkkkkxo::dkOOOOxl    //
//    OOOOOOOOOOOOkxooodkkkkxdxdoxO00d;.  ..;coxkkxo;''...:dxxxxdoolcccccclooodk0KKK0KKKK0Okxxxdccx00koooooooollc:;,,,,,,,'''''cdlokOkkkkOOOOxl;...:xOOOOkll    //
//    OOOOOOOOOOkdoodkkkkkkOkxxxoldo;.. .,c:cloooldkd,...,:dkkkkxdoolc:cccloodxxOKXXXXXXXXXXXK0kx0XX0xoloooooollc:;,,',,,,,'''':oodkxdoxkOOOkc....,dOOOOkocd    //
//    OOOOOOOOxoooxkkkkkkOOOOkkxd:.....';dOdoxkxxkkxl'...;lkOOOkxxdolcccllloddllx0KKXKKKKKXNNNK0KKOxdolloooooooollc:;,,,,,,'''';lc:;'.;xkkkko'....lkOOOOxcok    //
//    OOOOOOkdodkOOOOOOOOOOOOOxl,.....ck0xkkodxkkkd,.,,.';oO0Okxxxdoooooooodoc::dO00KKKKKKXXXXXXKkolooooooooooooollc:;,,;,,,,,'.... .'oxxxxd;....,dxxxxdccdx    //
//    kkkkkdlodxxxxxxxxdddddol;.....,dKXX0dxkddxd:.'oOo'';lxd;,:looddddddddoc:::ccodkO0KKKKKKXXKkdooooooooooooooooll:;;;;,,,,,..    ..,;,,,'. ....,,,,,'.',,    //
//    ::;;,,,;;;;;,,,,,,''''.......'cx0K0kooOXX0l,cOXKo,,;::...,:cloddolodollcccccccloxO0000000kdoddddddddxxxdddooolc:;,,,,,,'.  ...........   .............    //
//    ''...''''.....''..............',::;'';oxo;,dKXKOl;;,'...';;::;,'.;ooooooooooooodddxkkkkkxdddxxxxkkkkkkkkkxddol:'...',,,.. ............ ...............    //
//    '..'''...............................','':x0KKOolo:'...';;;'.. .'lddddddddxxxxxxxxxdddooodxkkkkkkOOOOxoloxxdl;.....',,'...............................    //
//    '''''...................................;d00OOoldd:...',;;'.....cxxxxkkkkOOOOOOO000000OOO0XXXKK0000kc'...:do,. ...,;,,................................    //
//    ''''''..................................,;:cllllol'..',,;,.....:xkkOOO00KKKXXXXXNNNNNNNNNNNXXKK00Ox:......c;...';::;;'.....,c;........................    //
//    ''''''''''...................................:ddc'..,,,;,.....;xOOOO0KXXXXXXXXXNNXXXXXKKKK00OOkxdc;;,.....'..':llcc:,.....'lo:'.......................    //
//    '''''''''''..................................,ld;..;l:,;'....'okkkkkO00OOkxxxxxkOOOO00OOOkkkkkxdo:cl'......':ooollc;......cdo;........................    //
//    '''''''''''...................................,;.';cxxc,.....ckkkkkkxxxddddoooodddxkkOOOO000Okkxlld:......'cdddool:,.....'lxl,.......................'    //
//    '''''''''''..........'''''......................'loldOd,....;dkOOkkkkxxxxxxdxxxxkkkOO000000000Ooldl'.....;:coddoccc;.....;lc,..........',,;:c:,'.....'    //
//    ''''''''''.........''''''.......................,lxxodc....'cdkOOOOOOOkkkdlcc:::ldO0000OOOOOOkoloo;......coccllloxx:......'.........':lodddooodc'....'    //
//    ,''''''''........''''''..........................,cxxc.....;odxO00000Oko;'...','..;dkxxxxxxxdlclo:......,lddddxO0KKl..............':odol:;,,''cdc'...'    //
//    ,'''''''........'''''.............................':o;....:dddxkO000xc,..,clodxdo;.'lddddddoccloc'......:oxkO0KXXXKx;...........':ldxx:'......'cd:'.''    //
//    ,,''''''........'''..............................',:;....'d00OkkOOxc'..;okOOkxo:;;..:oddddoccodo;......;dk00KKKK0OOOkdlclc;'...'cdxkkl'........,lo;'''    //
//    ,,,,,''........''...'''''''''',;,'.....'......',;cdl'....:dO0KK0kl,..'lOK000Ol'.....;dxxdlcodxdc......,okkOOOkkxxdddxkkkkkxl,..:dkOOo,..........,odl::    //
//    ,,,,,,'........''''''''''''';ldxdo:'.''......cdkkkx;....:xxxO00Oc...,dKXXXKKk;......:kxoloxkkkxc,;:loddxddollc:;,,'',;:okkkxc';oxOOx:...........';dkkk    //
//    ,,,,,,'.......'''''''''''';okOOkkkOd:'......,dkOOOl....,kXKOkOkc...'dKXXXXXXx,.....'colok0000Oxodxxdoc:;;,'............'cxkd;,lxkOkc'...........'':xkk    //
//    ,,,,,''......'',,,,,,,,,,ck0K0OkkkO0kc'.....:xOOOd,....lKNNNKOc....cOKXXXXXXO:..',,;ldOKKKK0OxdxOx:''...................,okl;cdkOOo,........'...'''ckO    //
//    ,,,''''.....'''''''''',,ckKXK0OOkOOxl:lc'..'oO00x;....:ONNNNNk,...;x00KKXXK0OxoooolokKXXXX0kdxkOOx:'.......',,,'........,oxccdxOOx:'.....'''''...'',lO    //
//    ,',,,,'''...'''''''''''':kKXK00OOOxc:dk:...;x00k:....'dKXXNX0l'..'o0KKKK0Okkdoc:;,',lOXNXOxdkOOOOx:'.....'':dkd:'.....'':xxloxOOkc''...'',;,'''...'';o    //
//    ,,,,,,''''..',,,,,,,,,,,,cdOKKK0Oo:lO0o'..'cO0Ol'....:k00Okkxdl;.;kXXXKOkkxdc''..''',oOXKkdxkOOOOx:'......'ckOxc'....''cxkddxOOOo,'...'''lxc''''..''';    //
//    ;,,,,,,''''''',,,,,,,,,,,:odkKKxc:oO0o,...;xK0o,',;:cdxkkkkxxxkl':OXKOkxkkl;,'.....'',o0KkdxkOOOOx:'......':ol:'....''':dxdxOOOd;''...'';xOx:'''...'',    //
//    ,,,,,,,,'''''',,,,,,,,,,,,cdolc:okOOo,..',lkOxoodxxkkxddolc;,cxl'cOOxxxOOd;''.......'';oOxdxOOOOOx:''....'''''.......''';dkOOOx:''...'',cddl;''''..'',    //
//    ;,,,,,,,,''''''',,,,,,,,,,,;;;lxkOko:;:cloxkkxxxdolc:;,,''''':xo';xxdxOOx:'''...'...''';oxdxOOOOOx:''.......''''''....''':xOOkl,''..'''',,'''''''...',    //
//    ;;;;;;,,,,,''''''''''''''';lookOOOxooxkkxddolc:;,''''''...''':xo',ldxkOkc,''...'''...''';oxxOOOOOx:''....'',:cc:,'''..''',oOOo;''...''''''''''',''''',    //
//    ;;;;;,,,,;;;,,,,,;;;:::cccdkxdO00OxxkOOd:;,''''''''''''...''':xo,;odkOOo;'''...''''...''';dkOOOOOx:'''...',lkOOOd;''..''',oOx:'''.''''',,;:clldl;,,;:c    //
//    ;;;;,,,,,;:cloddxkkkOOkkkkOOkk00kxxkOOOd;,,'..''''''''''''''':xkoodxOOx:''....''''''..'''':xOOOOOx:'''..'',lOOOOd;''..''':xkc,''.'',;cooddxxxkOOdoddxk    //
//    ;;;,,,:codxkO00OkxdollccccccloxOkkO00OOx:,,'''',,,,,,'''.''',:x0kdxOOkl,''...'';:,'''''''',cxOOOOx:'''..'',lkkxl;'''.''';okl,''''',,lxkxxxxxkOOkkxxxxx    //
//    ::;:coxkO000kxol::;;;,,,,,;;:okkkO00000xc,,'',,,,:ol;,'''',,,:xOxxkOOo;''''''',lxc''''''''',ckOO0x:'''..''';:;,''''''',:dOd;,;;::cloxxxxxxkO0Okxxxxxxk    //
//    ccodkO000Oxoc:;;;,,,,,,'',;:okkxxO00000kc,,'',,,,oOx:,,,'',,,ckkxkOOx:''''''',:xOd;,,,''''',,lk00x:,''...'''''''''',;cdkOOdoodddxxxkkxxdodk0Okkxxxdooo    //
//    dxkO000Oxl:;;;,,,,;;;;;;;;;okkxxxO00000x:,,,,,,,;oOx:,,,,',,,ckOkO0kl,'''',,,,:ll:,,'''''',,,;oO0x:,,''''''''',,;cldkO00Okxxxxxxxxkxdodo:;lddollc:::cc    //
//    kkO000kl:;;;;;;;;;::cccc::okxloxxk00000x:,,,,,,,;d0x:,,,,',,,ckOO0Oo;,'''',,,,,,''''''''''',,,;oOx:,,,,,,,;:clodxO00OO0Okxxxxxxxk0K00XNXd;;;:clodxk000    //
//    O000Odc:;;;;;;:coxkkOOOOkkOOl;oxxk00000d;,,,,,,,:d0xc,,,,',,,ck000x:,''''''''''''''''',,''',,,,:dd::cllooddxkOkkO0OxdkOkkkkkxxkOKXXXXXXX0xxkO00XNWWNK0    //
//    0KK0dc:;;;;;:lxO0000000000Oo;;oxxk0000Ol;;,,,,,,cx0xc,,,'',,,ck00kc,,'''''',,,,,;:cllc;,,;::clodkkxxxxxxxxxkOkkOOOxcoxxdoollcokXNNXXXKK000000OO0XNNX0O    //
//    KK0xc::;;;:cdO000000000000d:,cdxxO0000d:;;,,,,;;lO0xc,,,'',,;ck0Oo;,''',,,:clodxxkOO0OdodxxxkkkOOxxxxxdxxxOOkxddkOo::cccllodxOXXXXNNNXKKK00O000KXNNXOO    //
//    KKOo:::;;::oO000000000KKKOo:cdxxkO000xc;;;,,;;;:x00xc;;,'',;;ckOd:,,,,,,,:dOO00000000OkxxxxxxkOkxxxxxxxxdddlccoOXKkkOO000000OO0KK0KXXK0000000KKXNNXKOO    //
//    KKkl::;;::cx000xoolodOKK0OOkxxxkO00Oxc;;;,,;;;;oO00kc;;,',,;;ckxc;;;;;:cldO000000000OxxxxxxxkOOxxddoolcc:::ldkKNNNNNNNNXXKKK0000OOO0KKOOOOOOOO0O000000    //
//    KKkl:::;::cx00OkkxdloOK0OdokOOO00Oxoc;;;,,;;;;lk000kc;;;;;;;:lkdlooddxkO000OOkkkO00Okkxxxddoollc::::ccloxkk00KKKKXXXKK0KXXXK0K000OO0KXK0OOOOOOOOOO000K    //
//    KKkl:::;::clxO0KKK0OOOxdl::cxO00xl::;;;;;;;;:ok0000kl:ccloddxkOkkkkkkkOOkdollc::oxdoolcc::::clooddxxkO0KKKK0000000KKKK0OO0OkkOOkxxxkO00OkkkkkkkkkkO0KK    //
//    KKOocc:::::ccloddddolcc:::;:cdOOo:;;,,;;;::ldO00000OkxkkkkkO0OkxxxxxkOOxoloddddl:::cclodxkO00KKKK00OOOO0KK00KKKKK0000KK00Okxk00OOOkO0KK00OOkkOOOOO0KXX    //
//    KK0dccc::;::cccccc::::::;;,;:cdko::;,;;::cdkxx00000Okkxxxxk0OkxxxxxkO0OOO0KXXXXOddxO00KKXXXXXXXXKKK00OOO00OOO0KXXKK00KKKK00OO0XXKK0KNWNNXXKK00KKKKKXXX    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract G2U is ERC721Creator {
    constructor() ERC721Creator("Glory to Ukraine", "G2U") {}
}