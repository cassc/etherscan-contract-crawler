// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ARWed
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                               //
//                                                                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMWWMMMMMMMMMWWWWWMMMMWWMMMMMMMMMMMMMMMMMMM     //
//    MMMMMMMMN0kO000OxxOK0000OOOkkOkxkO0OO000OO00000K0O0KKKXXXKOOO0XXXXXX0kO0kk0KXXXXKkk00KK0OkkO0XXXXKOkkOKXXK00O0KXXKKXXXXXKOkOKXXKKKKKKKKKO0XXNWMMMMMMMM     //
//    MMMMMMMMXxdxxxoc::lxxxxkxlcldxxxxolodxkxl:okkkkkxldOO0000OxoldO00000OddxxdooxOOOOxllokOOkxdx00000OkxoxOOOkxlodxOOO000OkxO0kxk000OOOxxkxodkO0XWMMMMMMMM     //
//    MMMMMMMWXOxxxxdoolcldddxdddoldxxxoclxkkxoc:ldxxxolodxO0000xldkk0OxdxddkkkkdodddoxkxolxOOOkodOOOOOkkooxxxxxocoxkkkkxdxxodkOOOO000000kdodxOOO0KNMMMMMMMM     //
//    MMMMMMMW0xxxdddddxdoc:ldxxxxocodddolclolcccclool::::ldxxddodO0OOko::lxkkkkkOkxooxkkkddxdxxdoddxkdlllllddolcldddxxxdl::lxkkkkOkxkOkddkkdxkkOOKNMMMMMMMM     //
//    MMMMMMMW0olccoddxddololodxxxxollllcc:cloooccc:;;;;:::cc:::cokOkkocdxdddxxddxkkkooxkkkdodxxdddddddolllloolccclooodoclolldxxxxxdlcodxk0000OOOOKWMMMMMMMM     //
//    MMMMMMMWKo:;codooodxxxdlldxdoc:cllc:;;:c:;,,,,,,,,,,,,;;:cloxdlccdxxkxolccdxkkkxlldkkxdlc::;;::::;;::::::cc:ccc:::cllloooodoccloldkO000000OOKWMMMMMMMM     //
//    MMMMMMMWKdoolllccdxxxkkxolc:lolc:,,'',,,,,,'',,,,,,''',,;;::cooccdxxxoldxooddxkxoddoc:,,,,',,,,,,,,,,,,,,,,::::;;;:::ccl:;;:codxxxkO00KKKK00KNMMMMMMMM     //
//    MMMMMMMWXOxxdocldlldxxxdc:clc:,,''',,,,,,,,,,,,,,,,,,''''''',,;:lodlcldxxolloxxdl:;,,,',,,,,,,,,,,,;,,,,,,,;;,,,,;:;;::;;:;:oooddxxkO00KKXKKXWMMMMMMMM     //
//    MMMMMMMWKkxxxdxxxdllolclllc;,'''',,,,,,,,'''''''''''''''''''''''';:cc:oxdlldol:;,,,,,,,,,,,'';:llc:c:,,,,,,,,,,;cc:;,,;::clllooodxxkkO00K00KXWMMMMMMMM     //
//    MMMMMMMWKkxdddxxxxxo::clc;'''''',,''''''''''''''''''''''''''''''''',;cdkkxol::lo:,,,,,,,,,,,,;coxxdool::::;;:ccoolc:;,;:cccclloodxxxxkkkOddO0NMMMMMMMM     //
//    MMMMMMMWOdlcodxxxxxollc:;'',,'''''''''''''..''''''''''''''',,',,,,,,',;clc;;,:oc;,,,,'''',;;;::;;;:looxxxdlcoddlloc:;,,;:cccc:cllllcldoodoox0NMMMMMMMM     //
//    MMMMMMMW0dlcllccoocllc::c;,''''''''.........'''''''''''''''''',,,,,;;,,,',clc,,'',','''',;lxkOOkdol:,coxxollloolll:;;;,,;;;;:::cclollxOO0Ok0XWMMMMMMMM     //
//    MMMMMMMW0xxxkxddl;:lc:;lxo;''''''....................''''';:;,''',,,,,,,,,;:;,,,,'',,,,,,,,:ok00000kl:cdo:clllcccc:;;:;,;:::ccloodxxxkOOO0KKXWMMMMMMMM     //
//    MMMMMMMW0xxkxkkxolll:,';;;,''''''.......................';lxxoc:;;,,,,,,,,,,,,,'',,,,,,;::;;;:ldO000kolc;,;cc:;;;::;;::;:::::cooodxxxkkkO0KKXWMMMMMMMM     //
//    MMMMMMMWOdxxxxxolooc;;cc;''''''''......................',cxOO0OOkxl:,,,,,,,,,,,,,,,,,,;;;;:::cc:cx00Oxl;,,,;;;,',,,,,;;,;;;:cloooodxxxxkOO0KXWMMMMMMMM     //
//    MMMMMMMNxcoooodc:ol:,;ll:''''''''..............'..''''',:dO0000000Od:'''''',,,,,,,,,,;;;;;;;;:::lxOOxo:,''''''''''''',,,;,;:::cooodxxxxkkOO0KWMMMMMMMM     //
//    MMMMMMMNkoolcldccol:,',:c;''..''''............'''''';coxO000K0000ko:,''''''',,,,''',,,,,,,,,;coxO0kdc:;'''''''''''..',,;;;;:;;:ccodoldkkkOOOKNMMMMMMMM     //
//    MMMMMMMW0xkxdddolllc,':dxc'......................''',;lk000000Okl;''''''''''''''''''''','',:ok00Oko:,''''''''''''''.';::::ccc:c:ccoccddxkOkx0NMMMMMMMM     //
//    MMMMMMMWxlollloo:;ll;',;:;,,'.........................,oOOxdol:;,'''.'''''...''''''''''',:dk00OOxoc,''''''';;;,'''',,;::::cllccloddlldoloxddONMMMMMMMM     //
//    MMMMMMMWx:loooddllooc,'.'cdo;........................';cl:,'''''''''............''''''''ck00Okxdoc,'','',:codl:,'',;;;;;:ccllccoodxxdxxkkkod0NMMMMMMMM     //
//    MMMMMMMWkloddddddlcddc;,';cc;'...'..................',cl;''''.....................''''':xOOOkxoc;'',,,,,,;:cddc;',::;;;,::::cclodxkkxxxkOOOOKNMMMMMMMM     //
//    MMMMMMMWOdddddolll:cdolc;'.;oo;..............'',,'',,;:;'''......................'...':xOOkxdl:,'',,;;,:c:,,::,';:c::;:c:;;:;;:lodxkxxkOO00KXWMMMMMMMM     //
//    MMMMMMMWOolcoocclol:coooo:''::,...............'''''''................................';ldxxdl;''',,;;,;cddc;'',;::::::cc:cccc::ccldxxxkO00KKXWMMMMMMMM     //
//    MMMMMMMWOdo::odddollllldxo:,'...........................................................,:ll;'.',,;::;:cll:,,;;;,;;::cccoddllllclolcoxOOOKKKKNMMMMMMMM     //
//    MMMMMMMW0xdoloddddddolc:oxdlc:;,'......................'','...............................'''.',,;:odl:,,,,;:c:::;;;;:cokOxoloodxdoooxkdx0KKKNMMMMMMMM     //
//    MMMMMMMW0xdolodlloollodl:ldxddolc,....................'';:c,..................................''',;:ll,'';:::ccc::c:;:codddoooddxxxkOOdokOO0KNMMMMMMMM     //
//    MMMMMMMW0olloxxdcclodxdoodoldxxxdl;'..''...............'';:;........................................',,;cc::lllllcllcc::ccccloddxxkOOOkOOxooxXMMMMMMMM     //
//    MMMMMMMWx:ldxxkxxoldxxxxxolcldxxxd:,;,,;'..''............:xdc'.......................................,coolllclolclolc:cc:;,;ldxxxkOO000KK0OddKMMMMMMMM     //
//    MMMMMMMW0oddddxxoloxdoddocldoclodxdoc;,'',;;'............,odxl'.,'..................................:ccodddddoc;:llc:;::;;cccloxkkO0000000OkkXMMMMMMMM     //
//    MMMMMMMWKkxdololldxxdollddxdloddccdxdlc;;:,................;dko;:l;...............................'clllllodddoccc;;:;;:loddddodxkkk000K00OOO0NMMMMMMMM     //
//    MMMMMMMWKxdolccodxxxxxdoddxxxdlcllodddl,.......''...........;oxdc:;..............................';cldolcloodxdol:;;;:ldxxxxkkkkoldk0K000OOO0NMMMMMMMM     //
//    MMMMMMMW0oclddlldddddolodoloxdlodocloolc,..','.,,.............;dd:.................'''...........'';llllollodddolc:;;:lodxxxxkOkxkxookOkxkOO0NMMMMMMMM     //
//    MMMMMMMWOlodxxxdoodolclodxdllxkxdooxxl:cl,......'.............;okx:';:'..........''''..........';:ILoveYouoxxlcc:;:lll::lddodxkO000K0kkxodkOO0NMMMMMMMM    //
//    MMMMMMMW0dddxxxxoccoodxddddddxxxxxxoodocll:.....,::c:,,:,.....,cdxx:,;'..........'''..........';lddxdolclxkkxdl;,:loodxxdc;lxkOOO00KKkodxoodOXMMMMMMMM     //
//    MMMMMMMW0dddddloxdloxxxdddlcldoloxolodoclodl,'..';lo:';:......';ldxl'......................',,;cldxxxxddxoodxxoc:::codxxl;:oodxkkO000OkOOkddxXMMMMMMMM     //
//    MMMMMMMWOllolcldxxxxooddlcclodoc:clddoloxdclol;,'.;c'.',.':;,;;:dOkc'''..................':lllolcldddkOOOkdddolddolcldxdl::clccokOkxkOOOOOOkdKMMMMMMMM     //
//    MMMMMMMWOl::codxxxddocclloddddoolclooddoloo:cool:';l;'''.ckd:;,;odo;';:'................;::codddxxookO000OOko;lxkkkxxdlclllokkxxkddkOOOOOOkdxKMMMMMMMM     //
//    MMMMMMMWOoollodddoccodlcloddddoc:clc:loccodo::codl:;,,'.,d0x::dkxc,..,'...............,:;;;codxkkkxkkdoxOOOOdodooxkkxl;:c:coxOOOkxkxdxkOOOOkOXMMMMMMMM     //
//    MMMMMMMW0dooo:;cccloddddoolldocclodo:;coooolclc;cdl:cc,'ckOo:oOOd;...................;cc:cllcoddoxOOOkddddkOxoldxxxl:;,,,;coxxdk000OxdkkxxkkOXMMMMMMMM     //
//    MMMMMMMW0doolc:,;ldddddolc:;cooooodddolooodoccl:;ldlc:;cxkxc:xOOkoc;;...............,;:lodxkxdloxxkOOOOxoxkdllloxxc:c:,,,,,ldllxO0000OkooxkkOXMMMMMMMM     //
//    MMMMMMMW0oc:;cllcldddolccloc:cddodddolcloooccoollcodolodoolccxO0kkOOx;.............,;;cldxkkkkkOkdoxOxxOOOkdodxkkkxxo;''''';ldxddxO00OkkOxookXMMMMMMMM     //
//    MMMMMMMW0o::cooooodlcllloooooooooddl:cloc:codxdc:cooclddllododxxxOKKOl'........',,:lloolldddk00000Oxolx00000OkxodOOxoc,'''.':dkOOOOOdx000OxdxXMMMMMMMM     //
//    MMMMMMMWOoollooooclolcloooooool:;colloddoc:ldxddocldocododdxdooxOKKK0xc,......,c::lddkkkkdodkkO0000xdkOxxOOOOkdxkxocll;''''''ck0KK0xdkkk00OOOXMMMMMMMM     //
//    MMMMMMMW0dlccllc::coddodooool:coc;lddodddoloddddc;lxkdcldxxxxxxkOO00Okxoc;,,;cllcccokOkO0OOOkddxxk00000OxOOdox000Oxoldc,''''';dxxOK0KOxdk0OkOXMMMMMMMM     //
//    MMMMMMMW0olc::cccooodddoc:lcclooooooooool:cloc:clodxoclxxlcodxxxkkkO0OOOkkxxxoloddooxxdk000000kodO00KK000Ol;lk0KK0000x:'';:,';:lx0KKKKK0Okdx0NMMMMMMMM     //
//    MMMMMMMW0o::c::cloooddocc:;looooooolccolclddooc:codddddoddccoodkkxxkkkOOOOOkdccdkO00kddxkOOO0KOkOkdxO0000OddOxloxO0OOdc;,;;''';d00xdOKK0OddxxKMMMMMMMM     //
//    MMMMMMMWOc:::;:loloolc;:odoodddolccooccodddddddolooooolcdxxdl:looddxxdxxoodxddocoOOkO0Oxdxxk0KK000kdxddkkO0Okxoodxdxko;,,,'''',lOK0xdOOxk00kxKWMMMMMMM     //
//    MMMMMMMWk:cl::loollolcodxxxxocclccoddddddddxxxoccooccooodxxoldxoccldxdlcccdxxxxdlodxOKKKOdodk0K00000xoxOkO00Okkkxccdkxdoolccc;,:xKKK0kloO0O00XMMMMMMMM     //
//    MMMMMMMW0ccolllodoccoxxxkxl:lo::oxxxxxxxxocoxdloxkkxddxdlloxxxdloddddoddxoccoxxxddkkddk0OxkOxLoveBiggerxdxOOOOOkdxddO0000000kdxOKKK0ddO0kdxONMMMMMMMM      //
//    MMMMMMMMNK00KK0KKK0O0KKKK0xx0XKO0KXKXXXXXK0O0KKXXXXXXXKKK0OKKK0OKKKK00KXKK000KKKXXXXXKKXXXXXXK0KXXNNNNNNXK0XNNNNNXXNNNNNNNNNNNNNWNNNNNNNNNXXXWMMMMMMMM     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM     //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMYouRBeautifulMMMMMARW     //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ARW is ERC1155Creator {
    constructor() ERC1155Creator("ARWed", "ARW") {}
}