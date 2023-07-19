// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Modern Day Entropy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    .............,ll'.:,.....,:ld:......................................................................    //
//    .............;dl'.;,....,::lo'......................................................................    //
//    .............;dl'.,'....',';:.......................................................................    //
//    .............,oc.........'';c'......................................................................    //
//    .............'cc...........,:;''',,:,......',,'',,;;,,,''...........................................    //
//    .............,lc............',;,,,,::'....;:;,,;;::::::ccc:;'.......................................    //
//    .............cd:.................'';c:;;;:;,'',;::cccccccllooc;'....................................    //
//    ............,lo:.................'';lool;''''''',,,,;:cclllooddo:'..................................    //
//    ............;cl:..............'..',;ldc'.......'',,,,;;;clllloodxo,.................................    //
//    ...........,::c:..............''..,;ll'......,;,',,,;;:;lxdlcclodd:.................................    //
//    ..........,cclo;...............''';co:..';:;,cl,':lc;,,;lkOdc:clddl'................................    //
//    ..........,:clo:..............,cclol:'.,,,oxdddc,;;,'',cdOOkc,;lddl'................................    //
//    ..........',:loc'...........';llldc::'.,,':oooooc:c::cdOOxkOkxddddc.................................    //
//    ............';clc:;,.......',::;:oolo:',;:oxdoodxollookOook00kol:;..................................    //
//    ..........'...':ool;.''.....';clldkkdolllll:;;codoollokxdxxd:,......................................    //
//    ...............';;,...','....,;clokOddxkxllkOKXNNXXXXXXXNXx;........................................    //
//    ...............................,:lxxccdkkk0XXXNNNNNNNWWW0l..........................................    //
//    .................................':oooxxxxxkKNXKKKKXNNNNd...........................................    //
//    ....................................',,;:lodxO0kkkkO0KKXk'..........................................    //
//    ...........................................;oxkdllooxkkO0c..........................................    //
//    ............................................'lxdc::::oookd'.........................................    //
//    .............................................'oxl;,,,,,,ld:.........................................    //
//    ..............................................:xx;..''.,::,.....''..................................    //
//    .............................................';;::;,'..''...... .,:,'''''...........................    //
//    ..........................................':c:''..'''........... .cxxxxddc..........................    //
//    .........................................;okl;;...........';,...;oxkxkO0Oo'.........................    //
//    .......................................,cdOx,':,..'',;;::cc:'..,dkkkO0KXKd'.........................    //
//    .......................................cx0Kk;,:,'',,;;,,'......:O00KXKOKNx'.........................    //
//    .......................................:kKNXd:c,.''...........,o0XNNNX0KWO,.........................    //
//    .......................................;ONNWkccc:cl:'...'';lolcdXWWWNK0XW0,.........................    //
//    .......................................;0WWW0lc:,'.......,col;;kWWWWNKKNWO'.........................    //
//    .......................................;OWWWNxccc;;;;,'''',';lxXWWWWNNX0Xk'.........................    //
//    ........................................dNWWWk;,;:;;;;,cl:::cllkNWWWNNKx0k'.........................    //
//    ........................................,dXNWKl,'''',;::;';coodkXWWNNX0kKk'.........................    //
//    .........................................:KNNXo,;'.',;,...',cxk0NWWX0OOKNO,.........................    //
//    .........................................;KWNKc,;'..';,...',lox0NWNNXXKKNXl.........................    //
//    .........................................cKWW0:''...''..',;ldd0NWWWNNNXXXNo.........................    //
//    ..........,;;,,,,,,,,'''''''''''.......';xNWNx;'..''....;ldxkKWWWWWX0KNNWXl.........................    //
//    .........;dxxxxxxxddddddddddddddoooooodk0XWNkc;''',,,,,;:ok0NWWWWWWXKXNWWXl.........................    //
//    .........;dxxxxdolllloodxxkkkkkxxxxxkKXNNXOd:;,,,,,,,;:ldOKNWWWWWWWWNNNWWNd.........................    //
//    ........':xxxdl:,'',,'',:clllllc::coOKKKkc,;cc:;,;;;:lodxk0KNWWWWWWWWNNWWWk'........................    //
//    .......;coxxxo:;:;;,,,'''''''......';o00l,';ll::;;,;:loxk0XNNWWWWNWWWX00XNO;........................    //
//    .........:dxxd:;:loodxdlc;,'........'':l;'',:;,cc,',,;cod0XXNNNNNNWWKo:dXNOl........................    //
//    .........:dxxxdxkO0KXNNK0kdl:;'''''....'',,,:lc:;,,,cdl;l0KKKXXNNWWXd;lOXKko,.......................    //
//    .........:dxxxk0XXNNWWXOxdooolc:;''.';;,',,cxkxdddkOXXKKXXNNNWWNWWXx:ckXKOkx:.......................    //
//    .........:xxkKX0000KKK0Ox:.....',:c:lOkl::lxOkddxkOOxooox0KXNWWWWNx:cxXWWWNX0xlc;'..................    //
//    .........:xx0XNK0O000000Kd,',:cokxocloc;;lxxdoc:;;;;:codk0KXNWWWNk:ckXWWWWWWWWWWNKOkdl:,............    //
//    .........:xkKNNNXXXXNNNNWN00KXXXOl:;,;:lc:;,,,;::clokKNWNNKXWWWWKolxKWWWWWWWWWWWWWWWWWNX0k:.........    //
//    .........:xkXNWWWWNNNXXXXKKKOdlc;;;clldxxlclllxOkkOKNWWWNNNNWWNOoccdKWWWWWWWWWWWWWWWWWWWWWx.........    //
//    .........:xkKkox0NWNNNXKKX0o,...',;look0K0O0KXKxoOXNXXNWWWNXKOd;'';oONWWWWWWWWWWWWWWWWWWWXl.........    //
//    .........:xkk:..'lOKKXNNNXo'..',;:lkkdOXNXXNNXkoONWNKXNNX0xdl:,,',:lkNWNNWWWWWWWWWWWWXOdc,..........    //
//    .........:xxdl,.'ckkxxkOOx;.',;:clxKOxOK00NNN0x0NWNNXXXXXXXKKkc:;;ccxXXKNNWWWWWWWN0xl;..............    //
//    .........:xdclo::lOKkxxxxd:,;cldOKKK0OkOKNWWNKXNNNXXXXXXXXXNKooo;;::oKNNWWWWWNKko;'.................    //
//    .........:xo;:dl;;d0OkxxxxoldOOOXK0000XNWWWWWWWWNNNNNNNNNXXXOxKNx:cx0NWWWWKko:'.....................    //
//    .........:do::oo;,cxkOkxxxxkKNNNXOk0XNWWWWWWNNWWWWWWWWWWNNNNNNWWKOKNWWWNOl,.........................    //
//    .........:dolldo:;codk0kxxxxOKXNWNNNWWNKKNWWNNWWWWWWWWWWWWWWWWWWNNWWWWWNX0xoc,......................    //
//    .........cxdooxo:cdxxx0OxxxxxkOKXWWWWWNK00O0KKNWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNKOxoc,'................    //
//    ;,,,,,;codxxdxxo:cdxxkKKOO0KXNNWWWWWWWWWWWKkddxk0XWNWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNX0kol:;,,,,,,,,,,,    //
//    lllllloxkkkkkkxxlcloox0XWWWWWWWWWWWWWWWWWWNXKOkdoxO0NWWWWWWWWWWWWWWWWWWWWWWNNNNNNNNNNWNNXKOkxollllll    //
//    lokO0KXXXK0OOOOOxddodx0XWWWWWWWWWWWWWWWWWWNX0KXXkdxOKKKXNWWWWWWWWWWWWWWWWWNNWWWWNNNWWNNNNWWWNXK0kxol    //
//    lxOKXNWNNXXXKKXXK0OkxxOXWWWWWWWWWWWWWWWWWNNKOkKX00NNNXXXXXXXNWWWWWWWWWWWWWWWWWWWWNNWWWWWWWWWWWWWWNNK    //
//    lllodkO0KXXXXXXXXXXK0kxkKWWWWWWWWWWWWWWWWNNK0O0KKNWWWNNWWWNXXXNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    llllloooddxk0KXNNXXXX0kk0XWWWWWWWWWWWWWWWWNX0OOKNWWWWNNNWWWWWWNNNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNK    //
//    llllllllllllloxk0KXXXKKXXNWWWWWWWWWWWWWWWWWNKkxOXWWWWNNNNWWWWWWWWWWNNNNNNWWWWWWWWWWWWWWWWWWWWWWX0kdl    //
//    lllllllllllllllllodkO0KXNWWWWWWWWWWWWWWWWWWWXOdd0NWWWNNXNNWWWWWWWWWWWWWWNNWWWWWWWWWWWWWWWWWXKOxolccl    //
//    cllllllllllllllllllllodk0XNWWWWWWWWWWWWWWWWWNXxldXWWNNNXXKKXNWWWWWWWWWWWWWWWWWWWWWWWWWWNKOxdlllllccc    //
//    ccclllllllllllllllllllllloxkOKXNWWWWWWWWWWWWWWKolOXNNNXXXKKXNWWWWWWWWWWWWWWWWWWWWWWNX0kdolllllllllll    //
//    ccccclllllllllllllllllccclllcloxOKNWWWWWWWWWWWW0ld0KNNXXXNNWWWWWWWWWWWWWWWWWWWWWNKOxoollllllllllllll    //
//    ccccclllllllllllllllccccccccccldkKNWWWWWWWWWWWWNkllxXNNXXXNWWWNNWNNWWWWWWWWWNKOkdollllllllllllllllll    //
//    cccccclllllllllllcllcccc:::::lx0NWWWWWWWWWWWWWWWNx:cxXNXXXXNNNNNNNNNWWWWWX0kdollllllllllllllllllllll    //
//    cccccccllllllllllllllccc:::::::coxO00KNWWWWWWWWWWKxccOXNX0xxkO0XNNNNNNKOxolcllllllllllllllllllllllll    //
//    cccccccccccccclllllllcc::::cccccccccclxKNWWWWWWWWX0olk0XX0ocllxKNXKOkdllccclccllllllccclcclllllcclcc    //
//    ccccccccccccclllllllcccc:::ccccccccccccldxkkOO0XNX0olOKKKOdlloxkkdolllccccccclllllccccccclllllllllcc    //
//    ccccccccccccllllllllllccccccccccccllcccllccllodO00kddO00Okxdolllllollcccccccclllccccccclllllllllcccc    //
//    cccccccccllllllllllllllllllllllllllllllllllllllodddodkkxxdolllllllollcccccccccccccccccclllllllllccll    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MDE is ERC721Creator {
    constructor() ERC721Creator("Modern Day Entropy", "MDE") {}
}