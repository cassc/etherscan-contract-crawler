// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Final Bloom
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                        //
//                                                                                                                                        //
//    OOO00000KKKKKKXXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXNNNNNNNNNNNXXXXXXXXXXXXKKKKKKK000OOOOOOkkkkkkxxkkxxxxxdddddddddddd    //
//    OOOOOO0000KKKKKKKKXXXXXXXXXXXXXNNNNNNNXXXNNNNNNNNNNNNNNNNNXXNNXXXXXXNNNNXXXXXXXXXKKKKKK0KKK00OOOkkkkkkkkkkxxxxxxxxxdddddddddddoo    //
//    OOOOOOO00000000KKKKKXXXKXXXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNXXXXXXXXXXK0O0XXXXXXXXXXKKKK000KK000OOkkkkkkxxkkkkxxkkkxxddddddddddoooo    //
//    OOOOOOOO0000000KKKKXXXKKXXXKXXXXXXNNNXXXXXNNNNNNNNNNNNNNNXXXXNXK0OkdolldkKXNXXXXKKKK0000K0000OOOOkkkkkkkkkkkkkkkxxddddddddoooooo    //
//    OOOOOOOOOO00000KKXXXXXXKKKKKKXXXNNNNNNXXXXXXXXXXNNNNNNNNNNNX0Oxolllllcc:clx0XXXKKKKKKKKKKKK00000OOOkOOOkkkkOkkkxdddddddddooooooo    //
//    OOOOOOOOOOOO0000KKXKKKKKKKKKXXXXXNNNNNNXXXXXXXXNNNXXNNXXK0kdolcclccccc:::::cok0KKKXXKKKKKKK000000OOOOOOOOkkkxxddddddddoooooooooo    //
//    kOOOO000OOOO0000KKKKKKKKKKKXXXNNNNNNNNNXXXXXNNNNNNNNX0kxolllccccccccc:::::::::ldOKXXKKKXKKKK0000OOOOOOOOOOkxxdddddddoooooooooooo    //
//    kkOOO0000000000000KKKKKKKXXXXNNNNNNNNNNNXNNXNNNNNX0kdlcccccccccccc:::::;;:::::::cok0XXXXXXXXKK0OOOOOOOOOOOkxxddddddooooooooooooo    //
//    xkkOO00000000000000KKKKKXXXXNNNNNNNNNNNNNNNNNNX0xolccccccccccc::c::::::;;;;;;;:::::lx0XXXXXXKKK0OOOOOOOkOOkkxddddddooooooooooooo    //
//    xxkkOO000000KKKKKKKKKKKKKKXXXXNNNNNNNNNNNXNNXNKdccccccc:::c:::::::::::;;;;;;;;;;;;;;:ckXXXXXKKK000000OkkOOOkkxxddddddooooooooooo    //
//    xxkkOOOO0000KKKKKKKKKKK00KKXXXXXXNXNNXKOkOKXNN0occc::::::::::::::::::;;;;;;;;;;;;;;;;;dKXXXXKKK000OOOOOOOkkkkkxddddddooooooooooo    //
//    xxkkkkkOOOO0000KKKKKKKKKKKKXXXXXXXKOxdlccdkOKX0o:::::::::::::;;;;::;;;;;;;;;;;;;;;;;;;dKXXKKKK0000OOOOOOkxxxxxdddddooooooooooooo    //
//    xxxkkkOOOOOOOOO000000KKXXXXXXXXKkdl:::::coddxOkl::::::::;;;;;;;;;:;;;;;;;;;;;;;;;;;;;;oKXXKKKK000000OOOkxdddddddddoooooooooooloo    //
//    dxxxkkkOOOOkkkkkOOO0KKKXXXXXXXXx::::::::cllloddc;;;;;;;;;;;;;;;;;;;;;;;,,,;;;;;;;;;,,,oKXXXKK00000000Okxxddddddddooooooooolllllo    //
//    ddxxxxkkOOkkkOOO0000KKKKXKKKKXKd:::;;;;;:ccccll:;;;;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,oKXKKKK000OOO0Okxxdddddddoooooooooollllllo    //
//    ddddxxkkkkkkkO0KKKKKKKKKKKKKKK0d;;;;;;;;;:ccccc:;;;;;;;;;;;;;;;;,,,;;;,,,,,,,,,,,,,,,,l0KKKKK00OOOOOOxxdddddddoooooooooollllllll    //
//    ddddddxxkkkkOO000000KKKKKKKKKK0d;;;;;;;;;::::::;;;;;;;;;;;;;,,,,,,,,;;,,,,,,,,,,,,,,,,l00000O0000OOOkxddooooooooooooooolllllllll    //
//    dddddddxxkkkO0000000000KKKK0000d;;;;;;;;;;;;:::;,,,,,;;,,,,,,,,,,,,,;,,,,,,,,,,,,,,,,,lOOOOkkkOkkkkxdddoooddoooooooooollllllllll    //
//    oooddddxxxxkkO000OOOO0000000000o;,,,,,,,;;;;;:;;,,,,,,;,,,,,,,,,,,,,,,,,,,''''',,',,,,lOOOOOkkxdddddddoodddddooooooollllllllllll    //
//    oooooodddxxxxkO000OOOO000000000o;,,,,,,,,,,;;;;,,,,,,,,,,,,,,,,,,,,,,,''''''''''''''''l0K000Okxdddddooddddddoooooollllllllllllll    //
//    oooooddddddxxxkkOO0OOO000000000o;,,,,,,,,,,,;;,,,,,,,,,,,,,,'''',,,,,,''''''''''''''''l0K00Okxxdddddddddddddooooolllllllllllllll    //
//    dddddoddddddxxxxxkO00O000000000o,,,,,,,,,,,,,,,,,''''',,,'''''''''''''''''''''''''''''l0KK0Okkxxddddddddddddoooooollllllllllllll    //
//    dddxxdddddddxxxxxxkOO0000000000o,,,,,,,,,,,,,,,,''''''''''''''''''''''''''''''''''''''c0KK00OOkxdddddddddddooooooooollllllllllll    //
//    ddxkkkkxxdddxxxxxxxkO0000000000o,,,,,''''''',,,'''','''''''''''''''''''''''''''''''''.cOKKK00Okxxxddddddddddooodddoooollllllllll    //
//    dddxxxkxdddddxxxxxxxkOOO00000K0l,''''''''''''''''''''''''''''''''''''''.'''''''''''''.:OKKKK00Okxddddddxxxddddddxddooollllllllll    //
//    oodddddddddddddxxxkkkkkkOO0000Ol'''''''''''''''''''''''''''''''''''''''.............'.:OK000Okkkkxxxxxxxxxxxxxxxddooolllllllllll    //
//    ooooooddddodddddddxxxxkkOOO00OOl'''''''''''''''''''''''''''''''''''''.................:k0OOOOkkOOkxxxxxxxxxxxxxddoollllllllllllo    //
//    oooooooodddddddddddxxxkkOOOOOOOl''''''''''''''''''''''.''''''''''''''.................:k0OOOOOOOOkkxxxxxdxxxxdoollllllllllllllll    //
//    oooooooooodddddddddxxkkOOOOOOOOl'''''''''...''''.''''.....''''..'.....................;k0OOOOOkkOkkkkkkxxxxdoollllllllllllllllll    //
//    oooooooooddxdddxxxxxxxkkOOOOOOOl''''''''...................'..........................;xOOOOOkkkkkkkkkkkkkdooollllllllllllllllll    //
//    oooooooooodxxddxxxxxxxkkkOOOOOkc''''''................................................;xOOOOOkkkkkOOOkkkxxdoolllllllllllllllllll    //
//    oooooooooooooooddddxxkkkkkkOOkkc'.....................................................;xOOOOOkkkOOOkkxxddoooolllllllllllllllllll    //
//    ooooooollooooooooooddxkkkkkkkkkc'.....................................................;xOOOOkkkkkkkxxddoooooolllllllllllllllllll    //
//    oooooollllllooooooooodxkkkkkkkkc'.....................................................,xOkkkkxxxdddddoooooooolllllllllllllllllll    //
//    oooooolllllloooooooooddxxxxkkkxc......................................................,dkkkkkkxxddddooooooolllllllllllllllllllll    //
//    oooooooooooooooooooooodxxxxxkkxc......................................................,dkxxxxxxxxdddoooooolllllllllllllllllllloo    //
//    ooooooooooooooooooooooodddxxkkxc......................................................,oxxxxxxxdddddoooooooooolllllllllllllllooo    //
//    oooooooooooooooooooooooooooodxd:......................................................,odddddddddddddoooooooooolooooooollooooooo    //
//    ooooooooooooooooooooooooooooooo:......................................................,odddddddddddddddooooooooooooooooooooooooo    //
//    ooooooooooooooooooooooooooooooo:......................................................,odddddddddddddddooooooooooooooooooooooooo    //
//    ooooooooooooooooooooooooooooooo:......................................................,oxxxxddddddddddoooooooooooooooooooooooooo    //
//    ooooooooooooooooooooooooooooodd:......................................................,okxxxxxxdddddddddddoooooooooooooooooooooo    //
//    doooooodddddddooooooooooddddddd:......................................................;dkxxxxxxxxddddddddddddddooooooooooooooddd    //
//    dddooddxxxxxxxxddddddddddddddxx:....................................................;ldxxxxxxxxxxxxxxddddddddddddddddddddddddddd    //
//    dddddxxxxxxkxxxxxxxxxxxxxxxxxxxc....................................................:xkkkxxxxxxxxxxxxddddddddddddddddddddddddddd    //
//    dxxxxkkkkkkkkkxxxxxxxxxxxxxxxxxc.............''.....................................:xkkkkxxxxxxxxxxxxxxxxxxddddddddddddddddddxx    //
//    xxxxkkkkkkkkkkkkkkkkkkkkkkkkkkxc............''''....................................:xkkkkkkxxxxxxxxxxxxxxxxxxxddddddddddxxxxxxx    //
//    xxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkl'..........'''''....................................:kkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkl'......''''''''''...................................ckkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxo:'...'''''''''''...................................ckkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOkOl'...'''''',,'''...................................:kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOo'..''',,,,,,,,''..................................ckOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOo'.'',,,,,,,,,,,'..................................ckOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOO    //
//    00000000000000000000000OOOOOOO000o,''',,,,,;;;;,,'.................................'ckOOOOOOOOOOkkOOOOOOOOOOOOOOOOOOkOOOOOOOOOOO    //
//    000000000000000000000000000000000d;,,,,;,,;;;;;,,,'''.............'''........'''''''ckOOOOOOOOOkc:kOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000000000000000000d;,,,;;;;;;;;;;,,''''''''''''''''''''''''''''''''''ckOOOOOOOOkc..:kOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKx;,,,;;;;;:::;;;,,,'''''''''''''''''''''''''''''','ck0OOOOO0k:.   ;k0OOOOOOOOOOOOOOOOOOOOO00000    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKx:;;;;;;;:::::;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,lO00000O0x.    'x000000000000000000000000000    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKx:;;;;:::::::::;;;,;;,,;,,,,;;,,,;;;;;;;;;;;;;;;;;;lO0000000k,    :O000000000000000000000000000    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXKKXXKxc:::::::::cccc::;;;;;;;;;;;;;;;;;;;:;;;;;;;;;;;;:;lO0000000O;    ,k000000000000000000000000000    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKkccc:::ccccccccc:::::::::::::::::::::::::::::::::::lOK0000000c    ,kK0000KOk0K00KKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKklccccccccclllllcc::c::ccccccccccccccccccccccccccccoOK00KK0K0l.  .;OKKKKK0dckKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXKKKKXKKKKXKKXXKKXKO0KKKKKKkdoolllllllllllllllllllllllllllllllollllllllllllllldOK00KKKKKx'...l0K0K0K0o:xKKKKKKKKKKKKKKKKKK    //
//    OOOOkkkOOOOOOOOOkkkkkkkkxxxkkkkkxxdddddddoooooooooooooooooooooooooodddddddddddddddddxkkkkkkxddc'',.,lodxxxxoldxxdxkkkkkxxxxxxxxx    //
//    lllllllllllllllllllllcccccccccccclccccccccccccccccccccccccccccccccccccccclllllllllllllllc;,'.....   ....,;:::::;;::cc::::::ccccc    //
//    cccc::::::::::::::;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;;;;;;:::;;;;;;;;,,'......        ..'','''''......'''',,,,,    //
//    :::;;;;;;;;;;,,,,,,,,,''''''''''''''''''''''''''''''''''''''''''',,,,,''''''''''''.........     ..  .......''...................    //
//    ''''''''''''''''''''''''''''''''''''..........................................'''...............................................    //
//    ......................''''''.................            .......................................................................    //
//    ...............................................                             ........................................                //
//     ...............................................                                                                                    //
//                                              ..                                                                                        //
//                                                                         .    ..                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
//                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BL00M is ERC721Creator {
    constructor() ERC721Creator("Final Bloom", "BL00M") {}
}