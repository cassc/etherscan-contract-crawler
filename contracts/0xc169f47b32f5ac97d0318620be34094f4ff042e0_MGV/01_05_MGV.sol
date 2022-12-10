// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mignonverse Assets
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                               //
//                                                                                                                                               //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0kxooooodddxk0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0kxolc:;;;;;;;;;,''';lkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0kdl::cloooddoooodddoolc;,.,dXMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKOxoccllllloddol:,,:odxxdddxddl,'oOOkkkkOOOO0KXWMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0dlccloodddodddxxl'   'clldxxdlc::;;ldxOOO00OOkxxxkOO0NWMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOoccoooc:ldxxdddxxdl;',;,...;lccccldoloxddodk0000OkddxkxxkKWMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0oclooc;'...lxxxdxdoodkxdo;..,;coxxxxkdll:....;d00x:'...:k0kdOWMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKdcclloo;.....cddddoldkkdoccllodolodxxxxxo;......l00c......okdllOWMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXd:::clooc::cllooollloxxoc:cloxxxc...;oxxdol;....'ck0xl;'.'';:...,lOWMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc;;...:oc:;,;cdolcclool::cldol:cc'  ..lxdc;lxdlodkkdodO0Okkd:,..'lxo0MMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxc:l:'',:ll;...colloolc:::ldo:.....,;;codl::oxkkkkdlodxkkkkxdl::::cdOddXMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd:colcolcclccclllloooc::lodxx:. ....;cclc::oxddxxdodxOOOkdloxO0kdllodOko0MMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk:colcllcllldolllddoc;;coxxdoo:,,'',c;...':odddolldkOOOkdoodk0Oxoooodddoo0MMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKlcolclllloddoloddoc:'.'lddxdl:cdxxxdl'...'lxxdlodkkkxolldxdodo,....:oddclKMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMWNX0Oxdoooooodk0XWMMMMMNkccc:;;::col:llc:;;;'....:xkolldoooo::c:;cdddooxkkkdooodxxxdd:.  ....cddcdNMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMN0kdl:,.          ..;dO0kddl;,,,,',,;;,',,'....'.....:oc:looooolokxlodoodxkOkdlldkkkkxxxkc.  ...'ldooKMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMWXxlldxO0K0o.     .',,;,''',,''',;cooodollooooc;''',,;::;,,;:::;,,;odxxdlldkkkxooodxdxkkOkxddlc:;;:codoo0WMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMW0l''dXWMMMWNx. .';;::;,,,,,;;:c:coxkkkOkxxxxxxd:'';;,:loc;:odo:,',;::c:;,,coollooxxdoloxkkdooxkOOkxxxoloKWMMMMMMMMW    //
//    // MMMMMMMMMMMMMMWOc.  cXWWX0xc,.,:::c::cc:::;;;:cloxkkOOOkxkkxoddc,;:;;:c:::lxkd:;:lxxolc:;,;;,,,;cddodooollloxOOkkkxdoc:dXMMMMMMMMMMW    //
//    // MMMMMMMMMMMMMWx.  ..':c;'. .:c:;:cllccc::::;;:coxxddxxxddxdooo:',;,:l:;:ldkko;';odolcllc:;;;;,',colc:;;:cloxkOOOOkxo::xNMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMWOc;,''...    ',',cllc::::::;,,;codddddxddxddddo:',;;cc;;clolc:;,',c:,:ooc:::::;'':dolllcc:,'';dkkkkkd:l0WMMMMMMMMMMMMM    //
//    // MMMMMMMMMMWXkc'.               ..,;;::;;;;,,:loooddxddkkxxxd:.'',:;,',ll:;;:clcc:..;lc:c::c:clllllooooo,. ..;dxxdcckNMMMMMMMMMMMMMMM    //
//    // MMMMMMMMWKl'    .;cooc'           ..;::;,,,;ldxxkOO00KKKOOKk;',,'.....,;;:lodoccc::cc:ccc:cloolloodollc,...',clclxXMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMXo.   .cOXWMMMMXx,           .,c:;,;cdOKKKKXXXXXXKK0c'','.'','';ccccoolllll:colllc:clododolllllddoooc''',dNWMMMMMMMMMMMMMMMMM    //
//    // MMMMMM0;   .cKWMMMMMMMMM0'           .,;;:lddk0KK00XXXXXXKd,.''';c;,,:cc:ccccclccllodol:;coollll:::,;oxolo:;:oo:;dXMMMMMMMMMMMMMMMMM    //
//    // MMMMM0;   .dNMMMMMMMMMMMX:             ':lkkxxOKKKKXXX00XKd,..',;;,;c::ccc:::loooooo:,;;;clcclcc:c;.'clc:::okOkd::kWMMMMMMMMMMMMMMMM    //
//    // MMMMNc    oWMMMMMMMMMMMM0'             .;xOkxkO0KKXXXXKKXOdc',,';::::::::::colldoooc,..':llcclloddoc:;;codxkOOxxd:c0WMMMMMMMMMMMMMMM    //
//    // MMMMk.   .OMMMMMMMMMMMW0;               'odoook00KXXXXXXXOo:;c:;:,',;,',;cclolcol;;::;;;::'..:dxdc:cookK0OOkkkOOxl;dNMMMMMMMMMMMMMMM    //
//    // MMMWd    .lNMMMMMMMMWKo.                .cdoook0KKXXXXXX0xl;;::lolc:,'';clcclc:clccc:;;::;;;:::llldKXXKXK0K0xdkOkdcoXMMMMMMMMMMMMMMM    //
//    // MMMWo      ,oOKNNX0x:.                  .lxkxdOKKK0000XXKxc,,:ldxxxdllc:c:,;cccc:::::::cooldxdx0K0KXXXXXXXXX0kxxkxcl0WMMMMMMMMMMMMMM    //
//    // MMMMx.        .....                     ,xOkdx00OOOkxxOOOo,,;:ldddxddxdl:,,;;:lc:c:'..,lddk0XXXXXXXK00000KK000xddo::OWMMMMMMMMMMMMMM    //
//    // MMMMK;                                 .cOkxddxkOOOxdllcol;:lccoodxxxxdxdlc:;:c:;;;,,;ckOOKKKXXX0OOOxkOkxkkddkOxooccOWMMMMMMMMMMMMMM    //
//    // MMMMWk.                   .:xxc.       ,x0OOkxkO00Oxddool::clcldddxdddoxxddl:::cc:cdoclk0xxxxO0OxkO000K0000OkOkkdlccOWMMMMMMMMMMMMMM    //
//    // MMMMMWx.                 .xWMMWk.     .lO0OO0OOOOOOkxkkxxoccodxxxkOkxdodxodxxxxdddxkoldxddkkxkxdk0000KK00KKKKKOkdcclOWMMMMMMMMMMMMMM    //
//    // MMMMMMWO,                .xNMMNx.    .;d00OOOOxxOkkkxkOxxxlloxkkO00OOkddddxxxkkxdxxxdxOkdxO000OkO00Ok0KOkKK000Oko::o0WMMMMMMMMMMMMMM    //
//    // MMMMMMMMXd'               .,::,.   .;oloO0kOOOOOOOOOOOOkkxldxxOOO0OkxxddddxxkkxxxxdddxOkxk00000000KOO0KKKK0kO0kxo:lONMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMXx:.                   .;lodooOK000000000000000kodddkOO0KOkkddxxkxxkxxxxdolldkOOOkk0OOO000KKKKKKK0000d::kNMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMWKkl;'.          ...;lodoc:ckKKKKKK0KKKOk0K00kdxOkkOO00OOkddkxkxkxolccc:;,;lxkOxk0kxk0Ok0KKK0KK0kOOl;oXMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMWNKOo;'..'',;:;;coldl;,;oO00K0OOKKKK0KKOkxoxOxdddxkkkkddxxkkxxl,'''',;;coxOOO0Oxk0OO0KKOk00Oxxo;lKWMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMWO:.,:c::c:;:;;cc;;;cxkOKK00KKKKKK0kdoccloxxoodooddoddxxddl;',,,;::ldkOOOOOOO00000KK0000klcdKWMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMNd'.,::;::cc:::c:::cokOKKK00KKKK00Oxo:'',lxoloodxdodooocc:::::;:clodxkkO0K0KKK0kOKXK000ocdKMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMXo,';:;:cclllllccc:ldkO00OO0000OOkdxo;,'':lloolddl::cclolllll:::cddxOOdd0XKKXX0OKXKOxl;dXMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMKo:,,;;cclllolc::;:ldk00OkOKKOkOOodxlc;;:llclloocllododoccloc:c:lllol:;xX0OKXKKKKKOc;oKWMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMNkc;,;::::;,,;;;,':oxkkkk0XKOkkkdkkc:::cooloooolodxxdooloooc:c::::ll:;kXXXKKXXKkdc;l0WMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMWKxl:;:c;',lool:'.;oxkO0OKX00kxOK0l;:::cc::;;;;cxxxoclooool;,;:ccll:,o0XXK0KX0l':kXWMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMWKl'',.':lllc'.':dk0XXKKXXK0O0K0d:c:,;:::c:'';dkxdllllddl:'.;cccl:,ckKXK0kxl''xWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMKd:',clll;.';:;cx0XXXXXXXXXXX0kol;'coooo;',:dkdolloloolc;'',:lc:';kKX0dc,.',kMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO;':cl:,.,::::;:ok0KXK0KXXXXX0dc,,loooc'':cdkxddoddlllc:;,'':lc,,ok0d,..,;;kMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:,clc:,',;c;;::;,:okKKKXXXX00Od:',llol,.;ccclolooodoool:::c;';l;.:c;;ll;:c;dWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMKc,cc:oOK0Okdl,.,;,',cxO0K00XXK0Ol',lll;.,ccc::llldoodlcllcccc,.,,..;oONWKl;,cXMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMNo';:cxNMMMMWNO;......,:oxOO00KK00d''c:;'':llcc::cccllll::c:;;,'''...cXMMMMXl.'kWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMWk;,;lKMMMMMMMMk,,;'.,ll::clddxxdkOo'':,.';:ll::c;:c;:c:,,;;,:oookOo'.:XMMMMM0;.oWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMK:';xNMMMMMMMMWd,:;'lKWX0Okxddocclo:.';'.';,::.....',:::lokOOKNWMMMWk';KMMMMMW0okWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMNl.:0WMMMMMMMMMNl'',xNMMMMMMWNNXXK00x,.,cdk0O00kc.'';OXKXNWWMMMMMMMMMWOkNMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMWx,lXMMMMMMMMMMMK;.,kWMMMMMMMMMMMMMMMXc.;0WMMMMMMXo',dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMWOkNMMMMMMMMMMMM0,,OWMMMMMMMMMMMMMMMMWx'cXMMMMMMMMXl'xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxOWMMMMMMMMMMMMMMMMMMNxkWMMMMMMMMMXdkWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                               //
//                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MGV is ERC1155Creator {
    constructor() ERC1155Creator("Mignonverse Assets", "MGV") {}
}