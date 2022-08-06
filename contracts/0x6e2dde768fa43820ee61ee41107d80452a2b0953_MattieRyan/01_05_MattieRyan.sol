// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mattie + Ryan
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWWNXXXXXXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXXXXXXNNWWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWNKOxolc::::::clodxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kdolc::;;:::cldk0XWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWXOdc;,',,,;;::::::::;;:ldOXWMMMMMMMMMMMMMMMMMMMWNKkoc;;;;::::::::;;,,,,:lx0NMMMMMMMMMMMM    //
//    MMMMMMMMMWKdc,',;;cldxkO0000OOkxdlc:::cd0NWMMMMMMMMMMMMMMWXko:;;:cldxkO000000Okxoc:;,,;lkXWMMMMMMMMM    //
//    MMMMMMMWKd;,,;:lxOKXNNWWWWWWWWWNXKOxolc::lOXWMMMMMMMMMMWKxc;;:cokOKXNWWWWWWMMMWWNKOxl:;,,cxXWMMMMMMM    //
//    MMMMMWXx:,,;cok0XXXXXXXXXXXXXXXXXXXX0kdl:::lONWMMMMMMWKxc;;:lxOKXNXXNNNNNNNNNNNWNWNNKkl:,,,cONMMMMMM    //
//    MMMMWKo;,,;lk00KKKKKK000000000000000000koc;;;lONMMMWXkc,,;cdO0KKKKKKKKKKKKKKKKXXXXXXXX0xc;,';xNMMMMM    //
//    MMMWKl,,,;okOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxl:,,;dXWN0l;,;:okOOOOOOOOOOO000000000000000000kl;,',dNMMMM    //
//    MMMXo,',;lxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxoc;,,ldoc,,;ldkkkkkkkkkkkkkkkkkOOOOOOOOOOOOOOOkl;,';xNMMM    //
//    MMWx;'',cdxxxxkkkkkxxxxxxxxxxxxxxxxxxxxxxxxddl;,,,,,,:ldxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkxc,'':0WMM    //
//    MMKl''';oxxxxxxxxxxxxdddddddddddddddddddddddool:;,,;:lodddddddddddddddddxxxxxxxxxxxxxxxkkkxo;,',dNMM    //
//    MWO:'',codddddddddddddddddoooooooooooooooooooool:;:clooooooooooooddddddddddddddddddddxxxxxxd:,''lXMM    //
//    MWk;'',codddddddooooooooooooooooooollllllllllllllcccllllllloooooooooooooooooooooooodddddddddc,''cKMM    //
//    MWx,'',coooooooooooooooollllllllllllllllllllllllllccclllllllllllllllllllooooooooooooooooddddc,,'cKMM    //
//    MWO;'',coooooooooollllllllllllllllllllllllllccccccccccccllllllllllllllllllllllllllllooooooooc,,'lKMM    //
//    MM0c'',:lllolllllllllllllllllllllllllllccccccccccccccccccclllllllllllllllllllllllllllllooooo:,,,oNMM    //
//    MMNo''';cllllllllllllllllllllccllllcccccccccccccccccccccccccllllllllllllllllllllllllllllllol;,,;kWMM    //
//    MMWO;'',:cllllllllccccccccccccccccccccccccccccccccccccccccccccllllllllcccccccccccccccllllll:;,,lKMMM    //
//    MMMXo''';:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccclc;,,;xNMMM    //
//    MMMWO:'',;:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc:,,,oXMMMM    //
//    MMMMNx;'',;:::::ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc:;,,c0WMMMM    //
//    MMMMMNd,'',,;::::::::ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc::::::::;;,,:OWMMMMM    //
//    MMMMMWXo,''',;;;:::::::::ccccccccccccccccccccccccccccccccccccccccccccccccccc:::::::::::;;,,:kNMMMMMM    //
//    MMMMMMMXo,.'',,;;;:::::::::ccccccccccccccccccccccccccccccccccccccccccccccc::::::::::::;;,,:kNMMMMMMM    //
//    MMMMMMMMXd,.'',,;;;;;::::::::cccccccccccccccccccccccccccccccccccccccccccc:::::::::::;;,,':kNMMMMMMMM    //
//    MMMMMMMMMNx;..'',,;;;;;::::::::ccccccccccccccccccccccccccccccccccccccccc::::::::::;;;,,,c0WMMMMMMMMM    //
//    MMMMMMMMMMWO:'.''',,;;;;;:::::::ccccccccccccccccccccccccccccccccccccccc::::::::;;;;,,',oKWMMMMMMMMMM    //
//    MMMMMMMMMMMWKo,..'',,,;;;;;::::::ccccccccccccccccccccccccccccccccccccc:::::::;;;;,,'';xXMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMNx;..''',,,;;;;;::::::cccccccccccccccccccccccccccccccccc::::::;;;;,,'''cOWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMW0l,..''',,,;;;;;:::::cccccccccccccccccccccccccccccccc::::::;;;,,''';dXWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNk:'..''',,,,;;;;:::::ccccccccccccccccccccccccccccc::::;;;;,,,'',l0WMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWKd,...'',,,,,;;;;:::::ccccccccccccccccccccccccc:::::;;;,,,''':kNMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMW0l'..'''',,,,;;;;:::::cccccccccccccccccccccc::::;;;,,,''';dKWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNk:'..''',,,,,;;;;::::::ccccccccccccccccc::::;;;,,,''',l0WMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWXx;'..''',,,,,;;;;;:::::cccccccccccc:::::;;;,,,''',cONMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWKo,..'''',,,,,;;;;;::::::::cccc::::::;;;,,,,''':xXWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMW0l,..'''',,,,,,;;;;;::::::::::::;;;;,,,,''';dXWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl,..'''',,,,,,;;;;;;;;::;;;;;;;,,,'''';dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkc'..'''',,,,,,,;;;;;;;;;;,,,,,'''',o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXk:'.'''''',,,,,,,,,,,,,,,,''''',lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXx:'..'''''',,,,,,,,,''''''.,cONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;'..''''''''''''''''..'ckNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;'..'''''''''''...':kXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;....'.''.....':xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0o;.........':xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0o,.....';dXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0l,.';dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0kOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MattieRyan is ERC721Creator {
    constructor() ERC721Creator("Mattie + Ryan", "MattieRyan") {}
}