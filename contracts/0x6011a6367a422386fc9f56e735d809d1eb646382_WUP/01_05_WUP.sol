// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Wind Up Girls
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                       //
//                                                                                                                       //
//    ;..............................................'''''''''''''''''''''''''''....................................;    //
//    . ...                                    .....................................                                '    //
//    . ....                            ...........'''',,,,;;;;;;;;;;;;;;,,,,''''.......                     ...    '    //
//    .                            .........''',,;;;:::cccoooooooolllllllllcclc:cc;;;,....                   .'.    '    //
//    .                         .......'',,;;::ccllloooodooooooddddxxoddooolll,'cc;;ll;.....             ......     '    //
//    .                      .......',;;:ccloodxxkkkOOOO0Okddooolccll::::;,,'''.,:'.;;'.......  ..;cc::;'....       '    //
//    .                    .....'',;:cllodxkO00000K00OOkkOOkkkkxolllc;'.'....;:;:;..',;,,''...,:::looc;cc'.''       '    //
//    .                 .....',;;:clodxkO00000OOOkOkkkxddxxxdddolllldlc;'',;clol:,;;;:lc;;;;::lolcc;;c;':;          '    //
//    .               .....',:oxkkkO00KK0OOkkkOOkxxxdoc;:odddxxdokOdodkkkkkOkxdlcclccccllcloooccc:c:';:,',.         '    //
//    .             .....';:cd0K0kO0KK0Okkkkdlooc;,,,,,,;cc:::::;:ccldxxkO00K0Oxolooooolllc:l;....,::;c,',.         '    //
//    .            ....',;cok00OO000Oxollxxl:;;loodddxo::ooolccc:;,;,.,oo::oOOxdxdodoc;;;:ccoc;;;::c;.',..          '    //
//    .          .....,;:lx00OkO000koodkdlccloodooodxko'':::::;'';;:,..:lc:;oxollddllooo:cc.,c;:lcc:,..'.           '    //
//    .         ....',;clk00kOK0Odc,:ddddl:coxkxl:c:;;,',;::cccccccclc;;:;;:ccodlclc;,:looccclccc;,;::..'.          '    //
//    .        ....',:cokK0kOXKx:.'cloc:do;':xkxdc,'';;''',lolllodxollllooolloddollc,..,colc:::c:,.'';,..           '    //
//    .       ....',:cokK0k0Kx:'',,c:;'.;::;'co:c:',cdk:.;ooccclxXNK0klldl;,cdxdccc;,'';c:'';:c::,.'',:'.           '    //
//    .       ...',;cox00OOOl..cx:,oxxo;;:;,'.',;'.;xXKc,dl:dxolk0KK0xdccl:ldolc,.':c'.,,'''';:;;:,;;::..           '    //
//    .      ....,;cldOKkxo,..';,,lkOxc;,;::;;ldc..ckX0;,xl:dxddx00Odldl:dxxl:cccclc,,;'.,::,;c:,;:cc;...           '    //
//    .     ....',:cokK0xl:;;;,'.:xxl;.':;,:;,lx:..;xKXl'lxccoxdd00xxdoccodc:::coo:..:l;'';;,,:;',::;'....          '    //
//    .     ....';:ldkxl:;;:cllc;co:,,:;;::ll,,o:.'':oOO:'col:cllxxodolc;,clcc:colccllcccc;,',;::cc:;,....          '    //
//    .     ....,;clxl;:c:;;;:cloc,.;xKx,';::,;lollc;,:ol'',clodddollc;..''';:::::;;;;codxo;,;:oxdoc;,'...          '    //
//    .     ...',;coxdxXXKOdc,,;cc:,:x00kl,,,,;;clodoc;',;'.',,,;;,,:c;;;,'.'....,::,:x0OOOxodO0Oxdl:,'....         '    //
//    .    ....',;clxKWMWWWNKkc,,;:::clx0Kx:;,,;cllooooc:;';cc:,'..;:;;;,,,,,;;;:::;',xXKKKOdd0KOkdl:;'....         '    //
//    .    ....',:coOWMMWWWWWWNOl;,;cc:;coxxo;,;::cloolooc',oxxdlc:,...,;;,,,,;;;;;::;;cloooloOK0kdlc;,....         '    //
//    .    ....',:cxXMMMWWWX0OOOkd;',;:;;::col;,,',:::::::;:okkkko;..,;;,';:loool:;;:::::lk0kdkK0Oxoc;,....         '    //
//    .    ....';:lOWMMWWNx:;;,;:::;'.',;:;;;::,,,'......,;;lxkOxoc.';,,,:xOKKKKK0x:','.;ok0OdkK0Oxoc;,....         '    //
//    .    ....,;:oXMMMWWXl''''.,;:::;,',,;;;::,',''''''''':xO0kolc;,,'':kKXOl;,oKXO:.;:.'lkkxOK0Oxoc;,....         '    //
//    .    ...',;:xNMMMMWWKkdolc;'',:cc:;,,',;:;;cccccc::;:,,;:ll:c:;,,,cOXKd'..;x0Xd.;d:.:Okx0K0Oxoc;'....         '    //
//    .    ...',;cOMMMMMMWWWWNNXXOo;';odc;,'',;codxkxkkxoc:;..'::cl:::,,;dKKk,.,;cOKo'ckl.,kkk0K0kdl:,'....         '    //
//    .    ...',;lKMMMMMMMWNNNNNNNXOo;,ldl;,,;cdxddolodxxo:,;,'cdol:c:.':cc:,':dOKKk;;dOl.:kO0KK0xoc:,'....         '    //
//    .    ...',;c0WKxdxkOOKXXXXXXXXKx:,;l:,;:oxooxkkxooodl;;;:ccolc:,'..cocldOKKOxllkOkl;oO00KKOdoc;,'...          '    //
//    .    ...',;:dd' 'xK0OkkkOO0KKKKKkl:ol,:lddooOKKKkllxdc,':c';::clllcllccloooc:lxOkdodk000K0kol:;'....          '    //
//    .    ...',;:l:. .cO0OOOkkkkOO0000Okkd:;cdxxddxkkdoxxc,;:ldoc''l0K0Odolcccc:;,':dxxxx0K00KOdlc;,'....          '    //
//    .    ....,;:loc. 'xOxolclloxkO0KKXOxxo;;:oxxxddxddxdc;:::ccl:.;dkOkO0OOO0koc;;coxkkOOO0KOxol:;''....          '    //
//    .    ....';:cdko. ..',...'ck0XXNNNN0xkd:;cdocclllccc:,. .c::c;coc;,clodkOkxkkdollc:dkOK0xolc;,'.....          '    //
//    .    ....';:coOXkc:;;,..'oKNWWWWWWNXkdOKx:;;;;:;::;;lc..,ol;:ccl:'';dxccoOXXXOxo;'ck0K0kdlc:;'.....           '    //
//    .    ....',:cd0NKOxl,';o0NMMMMMMWWNXKxdxolc:::cldddololll:,'';;:lc::loc,:k0K0kxc,lkOOOkdol:;,'.....           '    //
//    .     ...',:lONNXKKKOxONMMMMMMMMWNXK0ko;,,,;:llloxOl,,;,,',cocldc,;cccccdkOOOxl;:ddddxxooc;,''....            '    //
//    .     ...',:xNWNNNWWWWWMMMMMMMWWNXKOkdoc;'..';:,,c;. .'..,:cooc:;;;:;coxkdxkd;;cloddllo:::;,'.....            '    //
//    .     ....,oXWWWWWWWMMMMMMMMWWNXK0kxolcc:;'..''......;,'':c;:dl'..,clc:clllllcc::ol:;;:c:;,''.....            '    //
//    .     ...'lKWNNNNNWWWMMMMWWWNNXKOkdolcccclcc:,'......:c:;,:ccoxocll:,,,,;;;;;:c::;;;,;:::;,'.....             '    //
//    .     ...lXWNXKXXXXNWWWWWWWNXK0Okdoolllodxxxxdl:,..',cddl;;;:cccloo:';,;c,';:ll;,;;,;:::;,''.....             '    //
//    .      .:KWXK0KKKOkONWWWWNNXXK0kxddoddxkOO0OOxdlc;;:lok0kc,:;'::::ldl;':l;;ll;;;,,:ccc:;,''.....              '    //
//    .      .'oxo:;;codclKMWWWNNXK0OOkxxxkkO0KKK0Okxoc:coxdkK0l;c:,;,,,;;;::cc;,::;:c:colc:;,,'......              '    //
//    .       ...'''';oddONMWWWNNXKK0OOOOO0KKXXXXK0OxolccdxxON0ooxlcodol;'lkxllooxOkkkxdol:;;,'......               '    //
//    .       .....',cONNWMMMWWWNXXKK000KKKXXNNXXK0OxdlccdxkKNOoxkolldkxllookddxxO000Oxolc:;,''......               '    //
//    .        ....';dXWWWMMMWWWNNXXXKKXXXXNNNNXXK0kxol:codOXXkdkdloddxdcoxllookO0000kdoc:;,,'......                '    //
//    .        .....:kKNWWWWWWWWNNNXXXXXXXNNNNXXK0Oxol::cldKKOdddccloxOd;oxldocok0000kdlc:;,''......                '    //
//    .         .....,;codxdkXNNNXXXXXXXXXXXXXKK0kdoc:;:ccxKOdool;:llxxclkoldl::lk000kdlc:;,''.....                 '    //
//    .          ......';coodOKXXXKKKKKKKKKKKK0Oxdl:;;::;:d0koooc,;ldxlckdcxxo;':x000Oxoc:;,'......                 '    //
//    .          ......:OKkxk0KKKK0000000000OOkdlc;;;;:;,,:xxllol:cooccxocxd:cl:;oO00Oxoc:;,'......                 '    //
//    .           .....,c:,cdkO00000OOOOkkkkxdlc;,'''''''.';:::cdo:;cooclko;'':ddxOkkOkdl:;,'......                 '    //
//    .           .....'',;;lk0KKK000Okkxxdolc;'...... .....'';clcccllcdxl'':;;lllodkOkdlc:,,'.....                 '    //
//    .            .....',;;l0WNXXKK0Okxdol:,............. ....;::::clloxdlllc::cdO000Okdl:;,'.....                 '    //
//    .            .....',,;lKWWNK0Okxdoc;'...,cl:;'.'..........,;;;,,,colcdc:ccodO0000Oxol:;,'.....                ,    //
//    .             .....',;:xKK0kxol:,'..';ldOOxc;;:,',,'......''..';:c;:ll:;c:lllkK000Oxoc:,''....                ,    //
//    .              ....'',;:looc:;,,;:ldkO0000xc;,:,.,ll;..',..,...,;;:c,,c;:c:lddkdddxkdlc;,'....                '    //
//    .               ....'',;;:cllloodxxxkkOO00k:.',;,'ckd:,''..''..',::cl::lloodkd:::;lkxdlc;,'....   ..',.       '    //
//    .               ......',,;::cclloooddxxkOOo. .oOOkkOkl.    .,,.',:c::lllodxdc::cc:lkkdol:;,'....;::llc;,.     '    //
//    .                 .....'',,;;::ccclloodxxkl..cO00000ko,... .';'';;::;:ddxxdd:;cdxlcokkdlc:;'.',:;;c:;,;:;.    '    //
//    .                  ......'',,,;;::cclllodd:..o0000000xl:'.. .::;coccccc;,:loooooo:;:dOxolllc;odc;:c:::;,;.    '    //
//    .                   .......''',,;;:::ccloo' .o0000000Odd:....;kOdkdc:;;,'.'':c;od;,:clllddlc::oo;;:..,,,;.    '    //
//    .                     ........'',,,;;:ccoo,..d0000000Okdo,...'dKOxOd:,,';l:'.'.',';;::clll,,;;;,,;:'.'.''     '    //
//    '                       ........'',,;;::ld:..cOO000000Okxc....,kXkxOo,'';dxc,''','..'',''..''''..,,','..      '    //
//    .                        .........'',,;;col. ;k0O0000000Ox:.,,.;kKkk0l..,okxo:,'';;,::;,'','''.;,...',..      '    //
//    .                          ........''',,;co;..lOOOO0000000x..;:',dOxOXd'.:ddl:,'';::lolc,.',;;';;...,..       '    //
//    .                            ........'',,;ll,..oOOOO0000K0o..co,..:ddkkl;ccllllcloxdl:col'.''';:,.''..        '    //
//    .                              .......'',;:l:..'okkkOOKXKx:'.:o:;;,;c::clllllolllcclooc:cl;''.;:;;;'...       '    //
//    .                               ......'',;;coc:;,cldOKK0OxxkkxocclooxxxkkkkkOOOOxddoooddddo::oxdlc;,'...      '    //
//    .                               ......',,;::loc;';ok00OOOOkxlllok00kdollllcc:oo;cl:;cddodxkxdxkxoc:,'...      '    //
//    .                               .....'',;:ccodxxkOkddxdddolldOK00KKKKXNNNNXK0kc..ldc;;;::cloooxxdl:;'...      '    //
//    .                              .....',,;:ldkkxxdccloodddlcdOKKK0XNWNNWWWWWN0o:ll;,od;,cddddoodlcooc;,...      '    //
//    .                             .....',;:okkdoc;codkxdkkl:oOKXNNKXWMMMWWWWWKd;cOX0kc;oo:dKNWN0Okxlodc;,...      '    //
//    .                            ....',;cdOkoc::oxO0xoxK0loO0KNWWNXWMMMMMMNKd,'oKNNN0dc:;coolxXWNd;clcc;,...      '    //
//    .                          ....',;cx0Oo::cok00kloKWKldKKKNWMMNNWMMMMWNk:.:kKKK0xdkx..xWO,.c0k' .cc;;'...      '    //
//    .                         ....',:d0Kd::clkK0OdlkNMNdl0XKXWMMWXXWMMWN0l,;d0K0ko,:OXOl:ldo:,;cc. 'oo;,'...      '    //
//    .                        ...',;oOXO:,::o0KOkll0WMMKoxXXKNMMMWK0WWWXx;'o0K0xc;;cooc;;;;,'.,lc''.,oc;,'...      '    //
//    o:::::::::;;;::::::;:::::cclookKN0,':,lKXOxcc0WMMMKloXXKNMMMW0ONNKd..dKKOl''cxd;.,okOO0kc:ldlllokxooolcc::;;;;o    //
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WUP is ERC721Creator {
    constructor() ERC721Creator("The Wind Up Girls", "WUP") {}
}