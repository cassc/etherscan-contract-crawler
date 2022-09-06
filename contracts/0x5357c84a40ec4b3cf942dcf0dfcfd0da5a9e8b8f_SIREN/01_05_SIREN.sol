// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sirenic - Limited Edition
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    xxxxxxkO00KXXXXXNXXNNNNNNNNNNNNNNNNNNXXK0kxxxxk00xdxkkddkK0OkxOXXXXXK00KOO0OkkdxO0kkKX0OO00XNK0KXNNNNWWWNXXKKXKKKKXNX0OO    //
//    kkkkkkkOOO000000KKKKKKXXNNNNNNNNNNNNXKKXK00K0kO0OO000kkkOKK00Okkkk0KXXXNK00KK000OkkkO0kxkKXXX0OO0XNNNWNNWWNNNNXXNNNNNK00    //
//    OOOOOOOO0000KKK000OO0OO0XNXXNNXXNNNNNKKXNNNXKK000KKK0OOOk0XXXXK0kkOKNNNXKOKXXNNXKKXXXKKK000K0OOOOKNNNNNNXNNWWNNXNXNNNNXK    //
//    KKKKKXXXKXXKKK0000O0000KXXKKKK00KKKXXXNNWWNNXXXXNXXXXXK0KKKXNNNXK0KNNNNNXNNNNNNNNNNNNNNXKOk0KKKK00KKXNNNXXNNNNNNXKKKXXNN    //
//    KKXXXXXXXXXKK000000000KKXKKK00OOOOOOOO0KKKKKKKKXXXXKK00KKKKKKKKK0O0K00000000000KKKK000KKK0KXXXXXXNX0KNNNNNXXXXXXXXXXXNXX    //
//    00000KKKKKK0000000OOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkxkkxxxxxxxxxxxxxxxxxxxdddxxkOO000000OOO0OOOOOOOOOOOOOkOkkk    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxkxxxxdddddddddddoooooo    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkOOOkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxddddddoo    //
//    OOOOOOkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkookkkkkkkkkkkkkkkkkkkkkxxxxxxdddd    //
//    OOOOkkkkOOkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkd;;xOkkkkkkkkkkkkkkkkkkkxxxxxxdddd    //
//    kkkkkkkOOOkkkkkkkkOkkkkOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxc.'dOkkkkkkkkkkkkkkkkkkkxxxxxxxxxx    //
//    kkkkkkOOOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkxxxkkkkkkkkkkko,..o0Okkkkkkkkkkkkkkkkkxxxxxxxxxxx    //
//    OOOOOOOOOOOkkkkkkkkkkkkkkkkxkkxxkxxxxxxkkkkxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkx;...c00kxxxxxxxxxxxxxxddddddddddddd    //
//    OOOOOOkkkkkkkkkkkkxxxxxxxkkxkkkkkkkkkkkkkkkkkkxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxc....;OXOkkxkkxxxxxxxxdddddddddddxdx    //
//    kkkkkkkkkkkkkkkkkkkkkxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOOkkko'....'dXKkkkkkkkkkkkkkxxxxxxxxdddddd    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkx;......lKX0kkkkkkkkkkxxkkxxxxxddxxxdx    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxkkkxxxxxkkxkx:.......:0NKOkkkkkkkkxxxxxxxxxxxdddddd    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxkkkkxkkkkkkkxkkkkkxxxxxxxxxxxc'.;;....,xNN0kkkxxxxxxxxxxxxkkxxxxdxdo    //
//    kkkxxxxxxxkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxkkkkkkkkxxxxxxxxxxxxxxxxxxxxkkkxl,..;:'....lOxdodxxxxxxxxxxxxxxxxddxxxxd    //
//    kkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxkkkkkkxxxxkkxxxxxxxxxxxxxxxxxxxxxxxkx:..'lO0x:'..';'':ooxxxxxxxxddddddoooooooo    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddxxxxxxxxkxc.,lOXNNNKx:'.'';OXxdxxxxddddooooooooooooo    //
//    dddddddddddddxdxdxxxxxxxxxxkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxdddddxxxxxxxdod0NNNNNNNNKkdloONWKxdxxxddddddddddddddddd    //
//    ddddddddddddddddddddddddddxxkkkkkkkkxxxxkkkkkxxxxxxkkkxxxxxkxxxxxxxxxxxxxxxxxOKKKKKKKKKKKKKKKXNNNNKkxdddddddddddodddddoo    //
//    ddddddddddddddddddxddxxddddxxxxxkKOlccccccccccccccccccccccccccc::::::;;;;;,,;kXXXXXXXXXXXXNNNNWWNNXkddoooddddddooodooool    //
//    ddddddddddddddddddxxxxxddddxxxxx00l;;;;;;;;;;;;;;;;;;;;;;;,,;,,,'''''''.....'xNNNNNNXkd0NNNNNWWXXWXkddddddddooooooooooll    //
//    oooooooddddddddddddddddddxxxxxdkKd;;;;;;;;;;;;;;;;;;;;;;;,,,,,''''''''......'xNNNNNN0o:xXNNNNWWKKWXxooooddoollllloooollc    //
//    dddddddddddddddddddxdddooddddxkKk:;;;;;;;;;;;;;;;;;;;;;;,,,,,'''''''''''....;ONNNNNNKdlkNNNNNWWKXWXxoooodooollcclloolccc    //
//    ddddoodddddddoooooOkc:::;;;;;cO0c;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,''''''''''''.;oddddddollodONNNWWXKNXxoooooooooolllllcc::c    //
//    ooooooooooooooodok0l,'''.....l0o;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,'''''''''''''...........;kNNNWW0dKXdlloollllllllllcccc:c    //
//    ooooooddddddddddx0x,''......:Ox:;;;;;;;;;;;;;;;;;;;;;;;,,;,,,,,,,'''''''''''''''''''''',dNWNNWW0dKXdlooooolccccc:::::;;;    //
//    ooooooooooddxxdoOO:''......,kk:;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,'',',,',,,,,,,,,,,lKWNNNWWKkXKdoollooolcc:cc:;;;;,,    //
//    oooooooloooodddk0o''......'dOc;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,:ONWWNNWWKKWXxllcllloooolllcc:;:cc    //
//    oooooooooooooox0x,........o0o;;;;;;;:;;;::;;;;;;;;;;;;;;;;;;;;;;;;;;,,;;;;;;;;,,;,,,,;dXWWWNNWNKKWNOocc:cllllllcc:::cllo    //
//    dddddddddoodddxxc'''''''',odccclllclllcllllllllcccccccccllllllcllcllcccccccccccccc:cccxXWWNNNWWXXWWXxlccccclllccccc:cccc    //
//    ooooddddoooooodkOOOOOOOOOO0O0XXXXX0kxk0XXXXXXXXKkxx0XXXXXXXXXK0OOKXXXXXXXXKKKKKKKKKKKKKNWWNNNWWNNWWXkdolllllllllllcccccc    //
//    llllloooooooooxKNNNNNNNNXNXXXNNNNKl..'l0NNNNNNKx:;:l0NNNNNNX0koookKNNNNNNNNNNNNNNNNNNNNNWWNNNWWWWWWXxooooooddddooooolccc    //
//    olllllooooooooxKNNNNKxdkKNXXXNNNNk;.'';kNNNNNN0oc:lokNNNNNN0xocccckXNNNNNNNNNNNNXKXNNNNNWWNNNWNNNWWXxllloooooooooooodooo    //
//    llllllloooooooxKNNNKd,.'oXNXXNNNNk;...,kNNNNNN0dooddONNNNNNKkxlodoxXNNNNNNNNNNNKxokXNNNNWWNNNWO:dNWKdlcclloollcc:::cllll    //
//    llooooooooooooxKNNNKo,,,lKXKXNNNNk,...,kNNNNNN0ddxddONNNNNNKkxodxokXNNNNNNNNNNN0dlxXNNNNWWNNNWx.lNWKoclloolloddolc::cccl    //
//    llllllllllllooxKNNNKo;;;dXXKXNNNNk,...,kNNNNNNKxxxdd0NNNNNNKkxooddkNNNNNNNNNNNNKOkOXNNNNWWNNNNd.oNWKoccccclllloooolccclc    //
//    llllllllccclloxKNNNXkxdxOXXKXNNNN0kdddxKNNNNNNKOOOkOKNNNNNNX0OkkkOKNNNNNNNNNNNNNNNNNNNNNWWNNNNo.oNW0l::::cclcccccccccccc    //
//    lllllllllcllookKXXXXXXXXXXXKXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWWNNNNo.oNW0l::::::clll::;::clll    //
//    ::::::;::;:::::cloodddxxxxdoddxxxxdoddoooollllllooooooooooddooooooooolooddddddxxxxxxxxxkxxxxdxl'ckkxc;;:::;;::cc:;;;:clo    //
//    ...... ....   ......',,,;;,,,;cllc;;;:ccccc:;;,;;;:::::;;;;;;;,,,''..'....'''.'.........................'....',;;;;;;:;;    //
//    ............  ..........................,,;;,,'.,,;;::::::::;;;;;;;,,''.........''''''''''''''..............',;:;,,''...    //
//    ''...',,'.''..........................................'',,',,,,;:::;;;,,,,'........'''''',,,,,,''''''......';:clc:;'....    //
//    ;,;;;;;;,,,,'...........'..'''............'...................';;;;::::;;;;,'..........',,,''...',,,'......;lccccc;,'..'    //
//    ''',,',,,,,,''''''''''.'''.'''''''''''....................''......',;;;;,,,',,,'........',,,'....',,,'..  .;::;;;;;;,...    //
//    '''''.............''''...''.','...................'..'......''.''...'.'''....'''''.......,,,'.....',,'..  .',;;,'',,,,'.    //
//    ''''''''''''',''''',,,,,,,,'.'....'.........'....'''',''.........'..,'.'......''''',,....',,'.. ...'''..  .''',;,..'',,'    //
//    ....''',,,,'''''''''',,,,,,,''''..'......'''.'......''''''''...........'..'''''''..';,. ..''..   ..'''..  ..'..','...''.    //
//    '..'''',,,,,,,,,,,'''',;;;;,,,,,,',,,,,,,',,.','''''''''',,,,,,,'.'''..''',,,'''..',;;. ..''..   ...'...  ..''.'''......    //
//    ,;;,,;;;,,,;,,,,,,,,'',,,;;,,;;;;;;,,,,,,,,''''',,,,,,,,,'',,,,,,'''''','''''.....';:,. ..''..   .......   .''...'......    //
//    ;::;;;::;,,,''',''',''''''',;;;;;,,,,'',,,''.'..',,;;;,,,,,;;;;;;:;,,',;'.''.... .',;'. ......   .......   .,;;,,,'.....    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SIREN is ERC721Creator {
    constructor() ERC721Creator("Sirenic - Limited Edition", "SIREN") {}
}