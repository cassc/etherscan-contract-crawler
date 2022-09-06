// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Apparatus Interdependence
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''.....,,,'''''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''''.,;'',lxol:,'''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''';lcldoccdO0KO:.''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''''''''cOkkxoloOKXXO;'''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''':kOxdkOkKNOo:''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''',lddk0NKKNd,'''''''''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''''''''''',:ldO0XWWWOo:''''''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''''......',:dkO0KNXOkdc:,'''''''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''''''''..    ... .':looO0dlcll,.,,''''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''.     ..   .''',:dOkxdo:..';,'''''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''''.. ..',.    .,'..'coool::;,'',''''''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''',;.   .,oo'     .,:'...'';:ldoc;:l:,''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''',cxx:.   ,dOl       ...';;ccokk00dc,';:,'''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''';kN0,  ...;OO, ...    ..',:lloOKXXk' .;c,'''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''',dXNo.  .'ckXd. ........,'..,:cdxO0c. .,l;.''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''lxOK:...,;;oO:............ ..,,;;;;...;do,'''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''.'dKXX:.;:;:,,c,.,;'........';:::;,',,:okOl''''''''''''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''.dNNWk'':::;::..,...  ..;cloxxxdc,;ldk0XO:.'''''''''''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''dNNNKo,cc:oxd,   .......:ldxkkkO0KXNNN0c''''......'''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''oKNNX0xooxKXOd:'...',,;:loxO000KKKKKXO:',;:lloooolc:,''''''''''''''''''''''''''    //
//    '''''''''''''''''''':kKXXXXX0kxkkdc;'...','....',;;;,,,,;:cox0XNNXXKKKXK0ko,''''''''''''''''''''''''    //
//    '''''''''''''''''''cOXXKXKKXXXK0kdl:,'......  ...'',;:cox0XWWXK0KKXXNNNNNXXk:'''''''''''''''''''''''    //
//    ''''''''''''''''',l0NWNNNNNNXXXXXXXK0Oxoc:;'.',;:lodOKXNWWXOkO0KNNKxlc:lkXNNKl''''''''''''''''''''''    //
//    '''''''''''''''''lKNXXXKOkO0KXXXXXXNNNNXK0kxxxkkOKXXXXK0xddkKNWNOl,..,;';kKNWXl'''''''''''''''''''''    //
//    '''''''''''''''',xX00XXXKO0000KXNNNXXXNNWNKkolcc::::cccldOXWNKxl,';::lddkOx0WWO;.'''''''''''''''''''    //
//    '''''''''''''''.:OXNWNOo;'',cxKXKXNNNXXXK0kxkO0000OO00KXNNNXOdlc,..'ck0K0OkKNWKc.'''''''''''''''''''    //
//    '''''''''''''''.:0WWKl'..'.  .,o0NNNNNNNNNNNWWWWWWWWWWWNX0xoclc..;;..c0N0O0XWWXl.'''''''''''''''''''    //
//    '''''''''''''''.:KWW0l...'...,::cdkKXNNNNNNNNNNNXXKK0kdl:....';,':l;':0WN0KNWWK:.'''''''''''''''''''    //
//    '''''''''''''''',kWWXk;.';clodddo:;;:ok000Oxdodoolc:;,,;;,;cdOx,.cxOOKNWWWNWWNd'''''''''''''''''''''    //
//    ''''''''''''''''';kNWN0xoc:::lkKKOkxO0KXXXXKKKKKKKKKK00KKKXNWXo;;lkKNWWWWNNWNd,'''''''''''''''''''''    //
//    '''''''''''''''''',ckXNNX0c....oXNXXNNNXXXXXNNNNNNNNNNNNWWWWW0xxodkKNWWWNXX0l'''''''''''''''''''''''    //
//    ''''''''''''''''''''';lx0k'  . .oNWWXKKKKXNWWWWWWWWWWXKKKKXWWXK0k0NNWWWWKxc,''''''''''''''''''''''''    //
//    '''''''''''''''''''''''',lc,:c;'cKWXo;,,,;:xXWWWNNWW0:,,,,lKWWN0kXWNXXWKc'''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''',odlodokNWXl'''''''lKWNXNMKc''''.;0WWWKOKNNXNWk,'''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''':xolk0XNWK:.'''''''oXNNX0o'''''.;0WWWN0dOWNNXo''''''''''''''''''''''''''''    //
//    '''''''''''''''''''''''''',oxx0KXWNd''''''''.cKWNk:,'''''.;OWWWKl,oNNN0:.'''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''';cdKXNWk,''''''''';OWWx;,'''''.,OWWKl'.cXWNk;.'''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''',lOKNWO;'''''''''''cKWXOl'''''',kWWx,'.;0WNx,''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''':kkxKXl'''''''''''',xNWWk,''''.;OWWx''',OWNx,''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''.cK0xKk,'''''''''''':OWKxc'''''.;OWWk,'.:0MNo'''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''',xXNXl''''''''''''c0WNo'''''''''oXWKl'.cKMXc.''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''cKWNd''''''''''',kNWNd,'''''''',dXWKl'cKMNo'''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''''''cKWNKd;''''''.'.;ONXNKOo,.'''''.'dNNKdoKXXd'''''''''''''''''''''''''''''    //
//    ''''''''''''''''''''''''.'lk0XNNNNKkxxxxddxxOXXXNNNXOxxxxxxxxOXNNNXXXX0d;'''''''''''''''''''''''''''    //
//    ''''''''''''''''''''':odxkKNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWWNWWWWN0xxo:'''''''''''''''''''''''    //
//    '''''''''''''''''''''xWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWk,.'''''''''''''''''''''    //
//    ''''''''''''''''''',lk000OOOkkkkkxxxxkkkkkkOOOOOOOOOOOOOOOOOOO000000000KKKKX0xl;''''''''''''''''''''    //
//    '''''''''''''''''',xXK00OOkxxxxxxxxxkkkOOOOOOOOOOOOOOOOOOOOOOOOkkkkOOOOO0KKKKXNk;.''''''''''''''''''    //
//    '''''''''''''''',:d0KKKKKKKKKKKKKKKXXXXXXKKKKKKKK000000KKKKKKKKK0000OOOO000000K0xl:;,,''''''''''''''    //
//    ''''''''''';:clloxxolcc::::;;;;:::ccccc::::::cccccccccclllooodddxxxkxxxxkkkxddddddddddddo;''''''''''    //
//    ''''''''''lOOkkkxxdoollllcccc::;;;;;;;,;;;::ccclllclllllllllllloodddxxxkkkOOO000KKKXXXNWWx''''''''''    //
//    ''''''''',xXXXXXKKXXXXXXXXXXXXXXXXXXKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNk,'''''''''    //
//    ''''''''''l0KKK0000000000KKKK000000KXXXXK000000000000000000000000OOOOOOOOO000000KKKXXNNXOc''''''''''    //
//    ''''''''''':okXWNNNXNNNNNNNNNNNXK00OO00000KXXNNNNNNNNNXXXKKKKXXNNNNNNNNNNNNNNWWWWNNNXOxc,'''''''''''    //
//    ''''''''''''''lKWWNNNNNXXXKKKKXXXXNNNNWWWWWWWWNNNNXXXXXXXNNNNXXXXXXXKKKKKKKXXNNNNNNKo,''''''''''''''    //
//    '''''''''''''''lKNNWWWWWNNNNNNXXXXXNXNWWWWWWWWWWWWWNNNNXXXKKKKKKKKKKKXXXXNNNNNNNNNWXl'''''''''''''''    //
//    ''''''''''''''':k000KKXXXXNNNNXXNNNNNNWWNNNXXKKKKXXXXXXNNNNNNNXXXXXXXXXKKKKKK000KKKKk:'.''''''''''''    //
//    looodddxxxxxxddxxxdoolllllllllcclcccccllcccccccccccccclllllcccccccccllllllooooddxxkkOOdddooollllcccc    //
//    XXXXXXXXXXXXXNNNXXXXKKKK0000OOOOkkkkkkkxxxxxkkkkkkkkOOOOOOOOOOOOOO0000KKKKXXXXXXNNNNNNWNNXXXXXXXXXXX    //
//    XXXXXXXXXXXXKKKKKKKKKKKXXXXNNNXXNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNNWWNNNXXXKKKKK0000KXXXXXXXXXXXXXXX    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AI is ERC721Creator {
    constructor() ERC721Creator("Apparatus Interdependence", "AI") {}
}