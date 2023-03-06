// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Death is only a Dream
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    WWWNWWNNNWWWWWWWWWWNNNNNNNNNNNNNWMMMWNNNNNNNWMWNNNNNNXXXNWWNNWMMMMMNKO0Kk0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXWMWWWWXNNXXNNXKOkkO0XNWWWWWWWX;                        ...            //
//    WWWNWWNNNWWWWWWWWWWNNNNNNNNNNNXNWMMMWNNNNNNNWMWNNNNNXXXXNWWNNWMMMMMNKOO0kONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMXXWWWNNNXXXXXXXKKOxkk0XXNNNWWWWX;                                       //
//    WWNNNWNNNWWWWWWWWWWNNNNNNNNNXXXNWMMMWNNNNNNNWMWNNNNXXXXXXWWNXWMMMMMNKkO0xONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWXKNNWNXXKKXKKXXK0kxxkOKXXNNNNNWK;                          .   .        //
//    WWNNNWNXNNWWNNWWNWNNNNNNNNNXXXXXWMMMWNNNXNNNWMWNNNNXXXXXXNWXXWMMMMMNKkk0xkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMWNNK0XNNXXK0KK00KK0OkxxxO0KXXXXNXNK;                          .   .   .    //
//    WWNNNNNXNNNNNNNNNNNNXXNNXNNXXXXXWMMMWNXXXXNNWMNXXXXXXXXXXNWXXWMMMMMN0xkOdkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWMMNXX0OKXXKK0O000000OOxddxk0KKKXXXXNK;                             ..  ..    //
//    WWNXNNXXNNNNNNNNNNNNXXXXXXXXXXXXWMMMWNXXXXXNWMNXXXXXXKKKXNWXKWMMMMMN0xkOdxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMWNNWWWWMWNKKOk0KK000OOOOOOOOkddddkO0KKKKKKX0;                             ..  ..    //
//    WNNXNNXXXNNNNNNNNNNNXXXXXXXXXXXXWMMMWXXXXXXXWMNXXXXXXKKKXNWKKWMMMMMN0xxOoxNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMNXNNWWWMWXK0kxO00OOOkkOkkOOkxdoddxOO00KKKKX0;                             ......    //
//    NNXXNNXXXNNNNNNNNNNXXXXXXXXXXXKXNMMMWXXXXXXXWWNXXXXXKKKKKNWKKWMMMMMXOdxkodNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMNXXNWNWWNK0OxxkOOkkkxxkxxkkxxooooxkOO00000KO,                             ......    //
//    NNXXXNXKXNNNNNNNNNNXXXXXXXXXXXKXNMMMWXXXXXXXNWNXXXXKKKKKKNWKKWMMMMMXOddkldNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMXKXXNNNWX0OkddxkkxxxdxxxxxxxdoloodkkOOO000KO,                             ......    //
//    NNXKXNXKXNNNNNNNNNNXXXXXXXXKKKKKNMMMWXXXXXXXNWNKKKKKKKKKKNWK0WMMMMMXOodkldNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMX0KXNXXXKOkxoodxxddddddddxxddlllldxkkOOOOO0k,                             ......    //
//    NNXKXXXKXXNNNNNNNNNXXXXXXXXKKKKKNMMMWXXXKKXXNWNKKKKKKK00KXW00WMMMMMXOodkcoXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWK0KXNXKK0kxdlloddddooooooddoolcllodxkkkOOOOk,                             ......    //
//    NNXKXXKKKXNNNNNNNNXXKKXXXXXKKKKKNMMMNXKKKKKXNWNKKKKKK000KXN00WMMMMMXklox:oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXN0O0KNKO0OxdocclooooolloloooolccccodxxkkkkkOx,                             ......    //
//    NNKKXXK0KXXXXXXXXNXXKKKKKXXKKKKKNMMMNXKKKKKKNWNKKKKK00000XN00WMMMMMXklld:lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKXOkO0NKkOkdolc:llllllclllloollc:cclodxxxxkkkx,                             ......    //
//    NXKKXXK0KXXXXXXXXXXXKKKKKXKKKK0KNMMMNKKKKKKKNWXKKKKK00000XN0OWMMMMMXkllo;cKWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWX0Kkxk0X0xxdolc::cccccc:ccccllcc::::cooddxxxxkx'                             ......    //
//    XXK0KXK0KXXXXXXXXXXXKKKKKKKKKK0KNMMMNKKKKKKKNWXKKKK000000XNOOWMMMMMXxccl,:ONWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNKOOxdxOKOddoll:;;::::::::::cccc::;::cloodddxxxd'                             ......    //
//    XXK0KXK0KXXXXXXXXXXKKKKKKKKKKK00NMMMNKKKKKKKNWX0000000000XNOOWMMMMMKxc:c,;xKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXX0kkdodk0koolcc;,,;;:;;;;;:::::::;;;::llooddddxd'                             ......    //
//    XXK0KX00KXXXXXXXXXXKKKKKKKKK0000NMMMNKKK00KKNWX000000OOO0KNOOWMMMMMKx:;:',oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKKOdxolox0xllc::,'',,,,,,,,;;;::;;;,;;:cllooodddo'                             ...       //
//    XXK0KX0O0XXXXXXXXXXKKKKKKKK00000NWMMNKKK000KNWX000000OOO0KNOkWMMMMMKx:,;.'cxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKO0koolcldOdc::;;'..'',',,',,,,;;;,,,,;;:clllooodo'                             ...       //
//    XX0OKX0O0KXXXXXXXXXKK0KKKKK00000XWMMNK00000KNWX00000OOOOOKNkkWMMMMMKd;',..;oXMMMMMMMMMMMWWWMMMMMWWMWWWNNNWWWWWWWWNOkOxllc:cokd:;;,,....''''''''',,,,,,,,,;:ccclllool'                              ..       //
//    XX0OKK0O0KXXXKXXXXXK00000KK00000XWMMNK00000KNWX0000OOOOOOKNkkNMMMMMKd;''..'cKMMMWWWNNXKKKKXWMMMMWWMNXK00KKKXXXXXXKkxkd:c;;:oxo;,,,'...........''',,''''',,;::cclllol.                                       //
//    XX0O0K0O0KKKKKKKXXKK00000KK000O0XWMMNK000000NWX0OOOOOOOOOKNkxNMMMMMKd;.....,x0OOOOkkxooodd0WMMMWWWMX0OxkkkOO0000Okddxl;;,,;lxl,'''...............'''''''',;;::ccclll.                                       //
//    XK0O0KOk0KKKKKKKKKKK0000000000O0XWMMN0000000XWXOOOOOOOkOOKNxxNMMMMMKo,...  .....';;;,''',;xWMMMWWWMKkdlooddxxkOkxdlldc,,'',cdc'.....   .................'',;;::ccclc.             ..                        //
//    XK0O0KOkOKKKKKKKKKK000000000OOOOXWMMN0000000XWXOOOOOOkkkOKXxxNMMMMMKo,..          ..    ..oNMMWWWWMKdl;:ccloodxdolcco:''..':o:......        .............',,;;:::ccc.                                       //
//    KKOk0KOkOKKKKKKKKKK00000000OOOOOXWMMN0000O00XWKOOOOOkkkkk0XxxNMMMMM0o,            ........lNMWWWWWM0l;'',,;:clol::;:l;.....;l:......           ...........',,;;;::c:.                                       //
//    KKOk0KOkOKKKKKKKKKK00000000OOOOOXWMMN0OOOOO0XWKOOOOOkkkkk0XxdNMMMMM0c.      .,coxO0KKXXKK0XWMWWWWWMOc'....',;:l:,,';c;.....,c;.  ..             ...........',,,;;:::.                                       //
//    KKOk00OkO0KKKKKKKKK0OO00000OOOOOXWMMN0OOOOO0XWKOOOOkkkkkk0XddNMMMMMO,   .'lkKWMMMMMMMMMMMMMMMMWWWWMk:.  ....',:,...,:,.....,c,.                     ........'',,;;:;.                                       //
//    KKOkO0OxO0KKKKKKKK00OOOOO00OOOkOXWMMN0OOOOO0XWKkkkkkkkkkk0XddNMMMMWx. .ckXWMMMMMMMMMMMMMMMMMMMMMMWMOc'     ...,'...';'    .':'.                       .......'',,;;;.                                       //
//    KKOxO0kxk0KKKKKKKK00OOOOO00OOOkOXWMMXOOOOOOOXWKkkkkkkxxxk0XddNMMMMWo'l0WMMMMMMMMMMMMMMMMMMMMMMMMMMM0o;..     ...   .;.     .;'.                         ......'',,;,.                                       //
//    KKkxO0kxk0K0000KKK00OOOOO00OkkkkXWMMXOOOOOOOXWKkkkkkxxxxx0XdoNMMMMW00WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKxl;'.    ...   .,.     .,.                           ......''',,.                                       //
//    K0kxO0kxk0000000KK00OOOOOOOOkkkkXWMMXOOOOkkOXWKkkkkkxxxxx0XooNMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXOxoo;.    ..   .'.     .'.                            ......'',,.                                       //
//    K0kxO0kdk0000000000OOOOOOOOkkkkkKWMMXOkkkkkOXWKkkkkxxxxxxOXooNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMNK00Kk,         ...     .'.                             ......'''.                                       //
//    00kdO0kdk0000000000OOOOOOOOkkkkkKWMMXOkkkkkOXWKkxxxxxxxxxOXolNMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMWWMWNNWWX;         ...     ...                              ......''.                                       //
//    00kdk0xdx0000000000OOkOOOOOkkkxkKWWMXOkkkkkOXWKxxxxxxxxxxOKolNMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMMMNNMMMMWWK;          ..     ...                               ........                                       //
//    00xdkOxdxO000000000OkkOkkOOkkkxkKWMMXOkkkkkkXW0xxxxxxddddOKllNMMMMMMMMMMMWMWWWMMMMMMMMMMMMMMMMMWNNMMMWX0k,          ..     ...                                .......                                       //
//    00xdkOxoxO000000000OkkkkkOOkkkxxKWMMXOkkkkkkXW0xxxxxdddddOKllNMMMMMMMMMMMMMWNWMMMMMMMMMMMMMMMMMWXXMMMNkol.          .      ..                                  ......                                       //
//    0OxdkOxoxO00000000OOkkkkkOOkxxxxKWWMXkkkkkkkXW0xxxxxdddddOKlcNMMMMMMMMMMMMMWNWMWMMMWWWNNNNWMMMMWXXWWNKc,;.                                                     ......                                       //
//    0OxokOxoxO000O0000OOkkkkkkOkxxxxKWWMXkkkkxxkKW0xxxxddddddkKccNMMMMMMMMMMMMMWNNWWNKOkxoc::lkKNWMWK0NXKk,...                                                      .....                                       //
//    0OxokOxoxOOOOOOOO0OOkkkkkkkxxxxxKWWMXkxxxxxkKW0xdddddddddkKccNMWNXXXNWWWMMWWXNWKl,...      .':okxdkkkd'                                                          ...                                        //
//    0OdoxOdodOOOOOOOOOOkkkkkkkkxxxdxKWWMXkxxxxxkKW0ddddddooookKccXKdl:::ok0NWWWNXNWd.               .':ldl.                                                           ..                                        //
//    OOdoxOdldOOOOOOOOOOkkxkkkkkxxxdxKWWWXkxxxxxkKW0dddddoooookKc,l,.    .,l0WWWNKNWl                  .,cc.                                                            .                                        //
//    OOdlxkdldkOOOOOOOOOkxxkkkkkxxxdxKWWWXkxxxxxxKNOdddddoooookKc          .xNMMNKXWl                   .;;.                                                            .                                        //
//    OOdlxkdldkOOOOOOOOOkxxxxxkkxddddKWMMXkxxxxxxKNOdddddoooook0:          .lNWWN0XWl                   .',.                                                                                                     //
//    OOdlxkdldkOOOOOOOOOkxxxxxkkxdddd0WWWKxxxxddx0NOdoodoooooox0:           :0XNN0XWl                   ..'.                                                                                                     //
//    OkdldkoldkOOOOOOOOOkxxxxxkkddddd0WWWKxdxdddx0NOoooooooooox0:           ,lxKXOKWd.                   ...                                                                                                     //
//    OkocdkocokOkkkkOOOkkxxxxxkxdddod0WWWKxdddddx0XOoooooollllxKc           .':kKkKWO:.                  ...                                                                                             .       //
//    OkocdkocokkkkkkkkOkxxxxxxxxdddod0WWWKxdddddx0XkooooolllllxKl             .dOk0WXx:'.               ....                                                                                                     //
//    kkocdkocokkkkkkkkkkxxdxxxxxdddod0NWWKxdddddd0XkooooolllllxKx.            .ckx0WWNKOl'.... ....,:do. ...                                                                                                     //
//    kkocdxocokkkkkkkkkkxdddxxxxdodoo0NWWKxddddddOXkoloolllllldX0c',cd;        ;xd0X0KXNXK0000OO0KKXNXx.                                                                                                         //
//    kkocdxo:oxkkkkkkkkkxdddddxxdooooONNN0xdddoodOKklllllllllldXWXKXWXc        'ddOx'.'',:clldxxdc;:lo:.           ..                                                                                            //
//    kkl:oxl:lxkkkkkkkkkxdddddxxdooooONNN0ddddoodOKxllllllcclcdXWWWXXO'        'ooko.                ..                                                                                                          //
//    kkl:oxl:lxkkkkkkkkkxdddddxxoooooOXNN0dooooodOKxlllllcccccdxol:'cd.        .llxl.                                                                          ..                                                //
//    kxl:oxl:lxkkkkkkkkxxdddddxxoooloOXNN0dooooodOKxlllllccccco:.   ,x,   .    'lcdl. .                                                                         ..                                               //
//    kxl:oxl;lxkkxxxkkkxxdddddddoooloOXXX0dooooook0xllllcccccco:.   ,kl.  ..  ,lc:oc......       ..    ..                                                       .                                                //
//    kxl;oxl;lxxxxxxxxxxddodddddooollkXXXOdooooook0xlcclcccccco:.   ,OO;..,;.,0kc:l:.......  ...                                                                                                                 //
//    kxc;oxc;cxxxxxxxxxxdoodddddolollkKXXOdooooook0dcccccccccco:.   ,0Xd,.:l.,Kk:;c;.......  ..                                                                                                                  //
//    xxc;odc;cxxxxxxxxxxdoooooddollllkKXXOoooollok0dcccccc::::l:.   ,KWO:'lx',0x;,:,........ .                                                                                                                   //
//    xxc;ldc;cdxxxxxxxxxdoooooddollllkKKKOoooollokOdccccc:::::l:.   ,KWXl,x0;,Od,,;,........                                                                   .                                                 //
//    xxc;ldc,cdxxxxxxxxxdoooooddollclkKKKOollllloxOdccccc:::::l:.   ,KMWd;kK;;Oo'','..... .                                                                                                                      //
//    xdc,ldc,cdxxxxxxxxxdoooooddlllclxKKKkollllloxOocccc::::::l;.   ,KMWx:kK;;kc..'.....  ..                                                                                                                .    //
//    xd:,ldc,:dxxxxxxxxddoooooddlllccx0KKkollllllxOoc::c::::::l;.   ,KMWx:k0;:k:..... ..                                                                                                                         //
//    xd:,ld:,:dxxxdxxxxdollooooolllccx000kollllllxko::::::;;;;c;.   ,KMWxckO;:x;..... ..                                                                                                                         //
//    xd:,cd:':dxddddxdxdollooooolclccx000kolllcclxko:::::;;;;;c;.   ,KMWx:xk,;d' .                                                                                                                               //
//    dd:'co:':ddddddddddollooloolccccx000kllllccldko:::::;;;;;c;.   ,KMWx:dd,;o'                    ....                            .                                                                            //
//    dd:'co:':ddddddddddollllloolccccdO00xlllcccldkl::::;;;;;;c;.   ,KMWx:do';o' .                  ...                                                                                                          //
//    dd;'co:':odddddddddolllllooccc:cdOOOxlcccccldxl:;;:;;;;;;:,.   ,KMWx:ol',l'                    ...                                                                                                          //
//    dd;'co;';odddddddddolllllooccc::dOOOxlcccccldxl;;;;;;;;;;:,.   ,0MWx:l:.,c' .                                                           .                                                                   //
//    do;'co;.;odddddddddolllllooccc::dOOOxlccccccdxl;;;;;;,,,,:,.   ,0MWx:c;.,c. .                                                          ..                                                                   //
//    do;.:o;.;odddddddddolclllooc:c::dkOOxlcccc:coxl;;;;;,,,,,:,.   '0MWx;:,.':. .                                                          ..                                                                   //
//    do;.:o;.;oddddddddolcclllllc::::okkkdcccc::codc;;;;;,,,,,;,    '0MWx;;'.';. ..                                                         ..                                                                   //
//    do;.:o;.;odoooododolccllcllc::::okkkdcccc::codc;,;;,,,,,,;,    'OWWx;,...,.                                                                                                                                 //
//    oo,.:l,.,oooooooooolcccccllc::;:okkkdcc::::codc;,,;,,,,,,;'    'OWWd;'...'.                                                                                                                                 //
//    oo,.:l,.,looooooooolcccccll:::;:oxkkdc:::::codc,,,,,,,,,,;'    'kNWd,.   ..                                                                                                                                 //
//    oo,.:l,.,looooooooolcccccll:::;;oxxxdc::::::lo:,,,,,''''';'    'kNNd,.   ..                                                                                                                                 //
//    ol,.;l,.,looooooooolcccccll:;:;;lxxxoc::::::lo:,,,,,''''','    'xXXo,.   ..                                                                                                                                 //
//    ol,.;l,.,looooooooolc:cccll:;;;;lxxxoc:::;;:lo:,,,,'''''','    .xKKo,.   ..                                                                                                                                 //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract death is ERC721Creator {
    constructor() ERC721Creator("Death is only a Dream", "death") {}
}