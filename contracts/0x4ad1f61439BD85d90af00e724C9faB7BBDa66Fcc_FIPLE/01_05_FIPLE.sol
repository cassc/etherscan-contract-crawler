// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions by Felix Inden
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                           //
//                                                                                                           //
//    | ____|__| (_) |_(_) ___  _ __  ___  | |__  _   _  |  ___|__| (_)_  __ |_ _|_ __   __| | ___ _ __      //
//    |  _| / _` | | __| |/ _ \| '_ \/ __| | '_ \| | | | | |_ / _ \ | \ \/ /  | || '_ \ / _` |/ _ \ '_ \     //
//    | |__| (_| | | |_| | (_) | | | \__ \ | |_) | |_| | |  _|  __/ | |>  <   | || | | | (_| |  __/ | | |    //
//    |_____\__,_|_|\__|_|\___/|_| |_|___/ |_.__/ \__, | |_|  \___|_|_/_/\_\ |___|_| |_|\__,_|\___|_| |_|    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNK0OOOkO0XNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNWWWWWWWWN0xl;,''''',:ok0XNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    NWWWWWWWWWWWWWWWWWWWWWWNNNNXXKKXXXXNNWNKOxl;''..........',:ox0NWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNN    //
//    NWWWWWWWWWWWWWWWWWNNNNNNXXK00OOOO0000Oo:,''................'';lx0NWWNNNNNNNWWWWWWWWWWWNNNNWWWWNNNXK    //
//    NNWWWWWWWWWWWWNNNNNXXXXKK00OOOkOOkxo:;,'.....'''''''''''''''...';lkKNXXXXXXNNNWWWNNNNNXXXXXNNNNXK00    //
//    XNNWWWWNNNNNNNNXXXKKKKK00OOkkkkkdl;,'..''',''''''''''''''',,,,'...';okOOO00KXXNNNXXXK0OkkO0KXKK0OOk    //
//    0XXNNNXXXKKKKKK00000000OOkkkkkdc;,'.'',,,''''............'''',;;,...',lxkkkOO000000OOkxdddxkOOOkkkk    //
//    kO00000OOOkkkOOOOOOOOOOOkkkkxl;,''',,,'''.....           ....'',;;,...'cxkkkkkkkkkkkxxddoddxkkkkkkk    //
//    xxkkkkkkxxxxkkkkkkkkkkkkkkkxl,''',,,''...        ........     ..',;;'..,dkkkkxxxkkkxxxddddxxkkkkkkk    //
//    xxxxxxxxxxxxxxxxxxxxxkxkxxxd;.',;,,'..     .....,;;;:::;;,'...  ..,;:;.'okxxxxxxxxxxxxxxxxxkkkOOkkk    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxc',;;,,'.     .....,:clllcccc::;,'...  .',:;.;xxxxxxxxxxxxkkkkkkkkOOOkkk    //
//    xxxxxxxddddddxxdddxxxxxxxxc',:;;,..   ...',;;:clooooollllcc:;,'..  .';:;.cxxxxxxxxkkkkkkkkkkOOOOkkk    //
//    ddddddddddddxxxxxddxxxxxkd;,::;;.   ..,:ccclloooddddoooolllc::;,..  .';;.;xkkkkkkkkkkkkkkkkkOOOkkkk    //
//    dddddddxxxxxxxkxxxxxxkO00k:;::;. ..,;cloooddddddddddddoooolllcc:;'.  .,'.ckkOOOOOOOOkkkkkkkkOOkkkkk    //
//    ddddddxxxxxxxkkkkkkkO0KKKk;,:;.  ':lodxxxxxxxxxxxxxxddddoooooollc;'.  ..,dkkOOOOOOOOOOOOkkkkkkkkkkk    //
//    dddddxxkkkxxxkkkkkkkOO000x;',.  .cdxkkkkkkkkkxxxxxxxxdddddddooooooc,.. .,lxkO0OOOOOOOOOOkkkxxxxxxkk    //
//    ddddxkkkkkxxxkkkkkkkkkkkxo;'. .,lxkkkkkkkkkkxxxxxxxxdddooolllllodddc,,. .;cokOOOOkOOOOOOkxxddddxxkk    //
//    ddddxkkkkxxxxxxxxxxxxddddl'. .'lxOOkdllcc::codxxxxxddlc:;,,,,,;:ldxd:,,..,:clxkkkkkOOOOkxxxdxxxxkkk    //
//    ddddxxxxdddddddddddddddddl. .'cxOOxollccc:ccldxkxxxddlc::;;::ccccldxl;,,;coocokkkkkOOOkkxxxxxxxkkkk    //
//    dddddddddoooooddddddddddxd;.,:dOOkddolc;;;:cldkkkkxxdoc::;'.';;:codxd:,:ll:lloxkkkOOOOkkxxkkkkxkkkO    //
//    oodddddddooooodddddddddxxxxlclk0Okxoooc::clloxkOkkkxdollllc:clollodxxl;:ol:clldxxkkOOkkkkkkkkkkkkOO    //
//    oooodddddoooooddddddddddldkxook0OOkkOkxxdddxxkOOkkxxxddooooooddddddxko::lolccloddxkkkkkkkkkkkkkkkOO    //
//    oooodddddooooooooddddddddxkdodO0OOOOkkkkkkkkOOOOkkxxxxdddddddddddxxxxdc:lolccloddxxxkkkkkkOOkkkkOOO    //
//    ooooooooooooooooooooodddxkxooxOO0OOOkkkkkkkOOOOOkkkxxxxdddddddddxxxxxdllol::cloddddxxkkkkkOOOOOOOOO    //
//    oooooooooooooooooooooooodkkddxOO00OOOkkkkkxxkkOOkkkxxxxdooddddxxxxxxxdolc;;:clloddddxkkkkkkOOOkkkkk    //
//    llooooooooooooooooooooooodkOkxOO000OOOkkxdooxkkkkxxxddooolloddddxxxxdooc,,;::cclooddxxkkkkkkkxxxxxx    //
//    lllllllooooollllllooooooooxOOkkOOOOOOkxddoodxdddddoollcllllclooddddddoc,';:::cccloddxxxxxxxdddooooo    //
//    llllllllllllllllllll:;;,,cdxkkkkOOkkkxdoloddddollccc:::cccl::cooddddo:'',;:c:;,:oddxxdddoolllccccll    //
//    lllllllllllllllllll:.   .:ocoxkkkkkkxdlcloooooolc::::::cccc:;:lodooo:,'';:c:,. ..,;::cc::;;;;;;;;;:    //
//    llllcccllllllllllll;... .:c:cldkkkkkxdlcllloooolllllccccc::c::looooc,..,:::'.       ...',,,'',,'',,    //
//    olllllcccccccccccl:'.....;lc::ldxxkxxxdlodxddddoollllllllooolcoolll;...,:;,.      .    .,;;;;;;;;;;    //
//    oooolllccccccccccc;.......,::::ldxxxxxddxkkkkxxddoooooodddddolllll:...',,,.       ..... .::::::::::    //
//    dddooollllccllllc;'.''..  ..'';::cccllodkOkkxxdollloooodddddolc:;'..'''''..  ....    ...,:c::::::::    //
//    ddddooolllllllllc'..'..  ......,,,...'';ldxkkkxxddddddddddolc;'..  .'......  ...... .':cccccc::::::    //
//    dddddooooolllllol;.....  ......',,...'..':lodddddoooooollcc;'.     ........ .......;lllllllccccccc:    //
//    ddddddoooooooooooc,..    ..''...,,........;:clollccccccc:;'..     ........  ......;llllllllccccccll    //
//    dddddddoooooooooooc'.......'''..,,'...'.. .':c:;;;,,,,,,'..      .'........ .....':ccccccccccccccll    //
//    ddddddddooooooooooo:........'''.',,...'..   ..'........        .';,.............',:::::cccccccccccc    //
//    ddddddddoooooooooooo;'.......''..','..... .'.......        ...',::,.............,::::::::ccccccclcc    //
//    dddddddddooooooooool:,......'..'...'...'. .;:,,'....    ..',;;;;;:,..............',;;::::::ccclllll    //
//    ddddddddddddoollc:;,,,''....'..''...'.... .',,,;,,.......''',,;;;;'..................',,,;:cclllloo    //
//    dddddddoollcc::;'..',...'.....''''..'.......',,,'''.....'',,,,;;;;........................'',;;::cc    //
//    ddddolcc:;;;;,'....''.  .''....'''..''.......''''',.....''',,,,;;'. .........  ...............',;;:    //
//    dooc:;;;,,,'.......'.. ....'.....'''''.......''''''.. ..'''',,,,'. .........   ...................'    //
//    l:;;,,,'''.......'''.............'''..'......''',,''','',,,,,,,'.  ........   .....................    //
//    ;,'''''''........'''..............'...''.....''',,'',,..',,,,,'.  .........  ......................    //
//    ''..''''.........''...................''......'''''';'..'''',,.. ..........  ......................    //
//    ....','...........'...........................''''',,,..',,''.............. .......................    //
//    ...','............'...........................'',,,,,,,'',,''............. ........................    //
//    ...''. ...........'....'.......................,;;;,,,,,',;;,'...........  ........................    //
//    ...'.. ...........'.............................,;;;,,;;,,;;,''.......... .........................    //
//    ...'.  ..........''...............................,:;,,,,,;:,''.........  .........................    //
//    .....  ..........'.................................;;,,,,;:;,'.........  ..........................    //
//    .....  .........''................ ................';;,,,;:;''.........  ..........................    //
//                                                                                                           //
//                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FIPLE is ERC721Creator {
    constructor() ERC721Creator("Editions by Felix Inden", "FIPLE") {}
}