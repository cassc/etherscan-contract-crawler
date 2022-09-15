// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GN//GM
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    SPECIAL.SHOUTOUTS.TO.Fetzer.and.White.Lights.for.help.with.the.backend.logistics.and.Stolen.Artists.for.being.the.realest.crew.in.the.game.               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx:l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo...'kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.....'xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,.......:0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc.........'xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx............c0NNXKOxdooxkO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;..............;,'..........';lxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.................................ckNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl......................';::'........:oOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;...................'ok0Oxo;...........dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx....................;dl;................dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;........................................:XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0x:........................................,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX000XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOd:'......................................:dkO0XWMMMNOollxKWMMMMMMMMMMMMMMMMMMWOc,...';dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMW0o;.........................................:XMMMMMMMXd;.....'o0WMMNK0000KWMMMMMMO'.'......'l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMNkc............................................;xONMMMMNl..........:lc;.....';lOWMMNl..','.......ckNMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNx;.................................................:d0MMNl.......................oXMNc.....'........;xNMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWO:...................................................'lOMMMKl.......................;kKc................:OWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWKl....................................................,kNWMMMMNO:.......................:l,.................lXMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNd'...............................................';:ldkXWMMMMMMMMN0dl:,,:cloodkOko'........,,'................,xNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMXc..............................................,cdOXWMMMMMMMMMMMMMMMMMWNNWMMMMMMMMWKc.........;ll;...............:0MMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMK:..................................................';cokXMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;.........cdxo:.............,kWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMK;........................................................;0MMMMMMMMMMMMMMMMMMMMMWWNWWMMMXd'.........':lc:;'...........lXMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMK:.......................................................,'.dWMMMMMMMMMMMMMMMMMMKdlc:;:cloxOOd;............,;'...........:KMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMM0;...........................................................lNMMMMMMMMMMMMMMMMWO,.',;;......':c,..........................;0MMMMMMMMMMMMM    //
//    MMMMMMMMMMMXc.........................................................,;.cXMMMMMMMMMMMMMMMMX:...........................................:XMMMMMMMMMMMM    //
//    MMMMMMMMMMNo..................................................':c;'..',:dKMMMMMMMMMMMMMMMMMNo..,'........................................:0WMMMMMMMMMM    //
//    MMMMMMMMMWx....................................................;xKXKKXNMMMMMMMMMMMMMMMMMMMMMXo............................................'xNMMMMMMMMM    //
//    MMMMMMMMM0,......................................................,xNMMMMMMMMMMMMMMMMMMMMMMMMMWKxc;'.........................................oNMMMMMMMM    //
//    MMMMMMMMWo....................................................':;..cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kdol:,'..................................kMMMMMMMM    //
//    MMMMMMMMO'....................................................,:ll'.oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKOdoc;'...........................lNMMMMMMM    //
//    MMMMMMMNl.....................................................;l:,..oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKkl'........................;KMMMMMMM    //
//    MMMMMMMO'................................,loodkO000Okkxxxdl:'...,'.cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0;........................lKMMMMMM    //
//    MMMMMMMx...............................'dXMMMMMMMMMMMMMMMMMWX0kxxx0NMMMMMMMMMMMMMMNOxkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO,........................;0MMMMM    //
//    MMMMMMXc..............................:KWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk;....lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.........................dWMMMM    //
//    MMMMMMO'.............................:XMMMMMMMMMMMMMMMMNKKKXWMMMMMMMMMMMMMMMMMMMk,ckOo'.,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMK;........................;KMMMM    //
//    MMMMMMx.............................;0MMMMMMMMMMMMMMMKo;'..':dKWMMMMMMMMMMMMMMMM0kNMMWk'.;0MMWXkoxNMMMMMMMMMMMMMMMMMMMWd.........................kMMMM    //
//    MMMMMWo............................;0WMMMMMMMMMMMMMW0;..;oo:'.'l0WMMMMMMMMMMMMMMMMMMMMNo..l0kl'.'xWMMMMMMMMMMMMMMMMMMMM0,........................xMMMM    //
//    MMMMMK;...........................,OMMMMMMMMMMMMMMM0;..lXMMWXx;.'dNMMMMMMMMMMMMMMMMMMMNo.....':xXMMMMMMMMMMMMMMMMMMMMMMNc........................kMMMM    //
//    MMMMMk............................lNMMMMMMMMMMMMMMXc..:XMMMMMMNk;.lXMMMMMMMMMMMMWXOxoc,....;xKWMMMMMMMMMMMMMMMMMMMMMMMMNl.......................'OMMMM    //
//    MMMMNl............................lWMMMMMMMMMMMMMM0,..dWMMMMMMMMNx;lXMMMMMMMMMM0c'.....'..'OMMMMMMMMMMMMMMMMMMMMMMMMMMMNl........................kMMMM    //
//    MMMM0,............................oWMMMMMMMMMMMMMMK;..lNMMMMMWWMMM0xKMMMMMMMMMMO;',cokKx'.'OMMMMMMMMMMMMMMMMMMMMMMMMMMMNl........................xMMMM    //
//    MMMMk'............................xMMMMMMMMMMMMMMMWd..'OMMMXx::lOWMMMMMMMMMMMMMMNXNWMMMx..'OMMMMMMMMMMMMMMMMMMMMMMMMMMMNc........................xMMMM    //
//    MMMMk.............................kMMMMMMMMMMMMMMMMK;..cXMMk....,KMMMMMMMMMMMMMMMXockWWd..'kMMMMMMMMMMMMMMMMMMMMMMMMMMMX:........................xMMMM    //
//    MMMM0,............................xMMMMMMMMMMMMMMMMWx...oNMXo;,:xNMMMMMWKddOXMMMMKc'dNNl...kMMMMMMMMMMMMMMMMMMMMMMMMMMMO'........................xMMMM    //
//    MMMMNl............................oWMMMMMMMMMMMMMMMMNo...dNMMNNWMMMMMMNx'.'lOMMMMMNXWMK;..'OMMMMWNXXWMMMMMMMMMMMMMMMMMNc.........................kMMMM    //
//    MMMMMx............................:XMMMMMMMMMMMMMMMMMXl...oNMMMMMMMMMNd....'dWMMMMMMMWx...,0WXkddk0XWMMMMMMMMMMMMMMMMWx.........................,0MMMM    //
//    MMMMM0,...........................'kMMMMMMMMMMMMMMMMMMXc...lXMMMMMMMNo......,OMMMMMMMX:...,oolokXWWNXXNNWWMMMMMMMMMMMO,.........................:XMMMM    //
//    MMMMMX:............................:XMMMMMMMMMMMMMMMMMMXc...:0MMMMMWd..;o,...lNMMMMNKo....cxO00OkOOO0XWMMMMMMMMMMMMMX:..........................oWMMMM    //
//    MMMMMNl.............................cKMMMMMMMMMMMMMMMMMMXl...,k0KNWk,..xK:...'kWNKK0x,...'okkxxOKNWMMMMMMMMMMMMMMMMNo...........................kMMMMM    //
//    MMMMMWd..............................:0MMMMMMMMWNXKOkdoc:,.....;dXK;..lNWd....;xddxko'...lKNWMMMMMMMMMMMMMMMMMMMMMNd...........................'OMMMMM    //
//    MMMMMMO'..............................;KMMMMMM0c,'..';:ldk0x,...oOc..'okdc.....:O0KXo...,OMMMMMMMMMMMMMMMMMMMMMWXO:............................;KMMMMM    //
//    MMMMMMNc...............................:KMMMMMKolox0KNWMMMMNx'.......:ddkOl'...,OWWk'...;xxddooodxk0NMMMMMMMMNOc,..............................oWMMMMM    //
//    MMMMMMMk'...............................;OWMMMMMMMMMMN0kxxxdoo:.....dNMMMM0d,...:XNo...,oddddxxxxdod0WMMMMWKd;................................:KMMMMMM    //
//    MMMMMMMNl.................................lKWMMMMMMMMXOkOXNWWMX:...lKWMMMMWNd....oNNkodKWMMMMMMMMMMMMMMWXOl'.................................;KMMMMMMM    //
//    MMMMMMMM0,.................................,dKMMMMWX0kxxdooooo:...:kKNMMMMMMK;....kWMMMMMMMMMMMMMMMMNOdc,...................................'OMMMMMMMM    //
//    MMMMMMMMWk...................................,dXWMNxccclodxxl'...lXMMMMMMMMMWx....;0MMMMMMMMMMMMNOdc,......................................,kWMMMMMMMM    //
//    MMMMMMMMMNo....................................,lkXWWWMMMMXl....oNMMMMMMMMMMMK:....dWMMMMMMMMMNx;.........................................:0MMMMMMMMMM    //
//    MMMMMMMMMMNl......................................'ckXWMMMO,.':OWMMMMMMMMMMMMW0l::dKMMMMWKOxdo;..........................................:KMMMMMMMMMMM    //
//    MMMMMMMMMMMNo........................................':x0NWX0KWMMMMMMMMMMMMMMMMMWWMMNKOo;...............................................;0MMMMMMMMMMMM    //
//    MMMMMMMMMMMMWk'..........................................;:ldkKNNXKKKKK0OOOOO0KXX0xc;'.................................................;0MMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMW0;...............................................,,'.............''.....................................................;0MMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMXl....................................................................................................................;KMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWOc'................................................................................................................lKMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWKo,............................................................................................................:OWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNk;........................................................................................................:OWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMNx:....................................................................................................,kNMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWKx:...............................................................................................,dXMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl,..........................................................................................'dXMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc.......................................................................................:0WMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l'................................................................................,ldONMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl............................................................................;lxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKdc;...................................................................;cokKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0dc,...........................................................;okKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkdl:,.................................................,cdk0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0xoc;,,;;....................................'cx0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNNKOkxdoolc;,............',,,;:clodxk0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXK0OkxxdodxO0KNNNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GNGM is ERC721Creator {
    constructor() ERC721Creator("GN//GM", "GNGM") {}
}