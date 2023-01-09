// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DEATH of DOLCE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    NNNNNNNNNNNNNNNNNNXXXXXXXXXXXXXXNNNNNNNNXK00OkxkOOOkkOKXNNNNNNNNNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    NNNNNNNNNNNNNNNNNNNXXXXXXXXXXXNNNNXK0koc;''..,,;;;;,'.;ccdOXNNNNNNNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    NNNNNNNNNNNNNNNNNNNNXXXXXXXXNNXKkdol:;;'.....,:;'..',;:;,:cldOKXNNNNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    NNNNNNNNNNNNNNNNNNNNNXXXXNNX0xoc;,,,'''.',,:c:,;lcc::;;:::,,;;:okKXNNNNNNXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNKxl::cl:,''',,,,'.,ll:co:,'.,::'.,clc;''cx0XNNNNNNXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    NNNNNNNNNNNNNNNNNNNNNNNKxc,.',,,;;:clcccl:.,;;;:c,.',;;'.':cc:,'.',:d0XNNNNNNNXXXXXXXXXXXXXXXXXXXXXX    //
//    NNNNNNNNNNNNNNNNNNNNNNOl;,;:;:;:c'';;;::::,;coddd:,;;,,;::cl:''',;;,,ckKNNNNNNNNNXXXXXXXXXXXXXXXXXXX    //
//    NNNNNNNNNNNNNNNNWNWWNk,.'';:clcloc::codddocllll::;;clllc:,',,..''','..:xKXNNNNNNNNNNXXXXXXXXXXXXXXXX    //
//    NNNNNNWWNWNNWWNNWWWXx;...';;,,,';c:,,;;:clc;:c::lolllc;;,,;:;;'......,:lx0XNNNNNNNNNNNNNNXXXXXXXXXXX    //
//    WNNWWWWWWWWWWWWWWWXo'...;lolccl:;;;,;::clc:;:loc:::;;;'..';cc,...::;;,',cxKXNNNNNNNNNNNNNNXXXXXXXXXX    //
//    WWWWWWWWWWWWWWWWWXl...,,,:ccclolll;;c:;;,,;,;;,,,;;;::;.....'..,:c:,.. .,lkKXNNNNNNNNNNNNNNNNNXXXXXX    //
//    WWWWWWWWWWWWWWWWXo...'clc;,'';;,;;,;;'',;:cc;,,:lc:,....,;'...,;,... ...';lkKXNNNNNNNNNNNNNNNNNNNXXX    //
//    WWWWWWWWWWWWWWWXo''. .':llclll:'..',;ccclc:;,;:;,''...'.',,..;c;. .......,:oOKXNNNNNNNNNNNNNNNNNNNXX    //
//    WWWWWWWWWWWWWMWXkl;';,.'''';cccc,...;lolc:;::c:,....,;,....,,;;,..';.....;;:dOKXNNNNNNNNNNNNNNNNNNXX    //
//    NNNWWWWWWWWWWMWXxc'.::',;,''..,c,....',;;llc;'''',;'......',,....','... ..;oxO0XXNNNNNNNNNNNNNNNNNNX    //
//    NNNNWWWMMMWWWWOl:,....';;,;lc'',..''...;;,'..,;;;;;'..,;'. ..,''',...'.   ,kKKXXNNNNNNNNNNNNNNNNNNNX    //
//    XXXNWWMMMMMMNklc:'',..''...;c;;,.,:'.''....',:;'.....''......;:;:c:'....  .c0XXNNNWWWWNNNNNNNNNNNNNX    //
//    XXXNWWMMMMWXxl;,......'.....'';::lxo;;:'..:oxkdlcc::;,...''...,..:c. .'',,';dKNNWWWWWWWWWNNNNNNNNNNN    //
//    NXNNWWMMMW0o:;:c::lc,,,;:;,,coxkO0KXK0OxddkOOKNWWNXX0OOkdl::lol,'co:,,:clc;''l0WWWWWWWWWWWWNNNNNNNNN    //
//    NNNWWMMMW0c:::lloool:c::ollkXX0kkOKXNWWMMMWWWWWWWWWWWKOxodOXNNk;;looc;;::;,''':xXWWWWWWWWWWWWNNNNNNN    //
//    WWWWWMMMXo,:lolc:;:lcol:odcoxkOkO00OkkxONWMMMMMWWNNNKo,;lk0KNNk:;;:ol;',;::loo;,ckNWWWWWWWWWWWNNNNNN    //
//    WWWWMMMWOl:clodxxdxkxxdlodlokNMMNOxo::cdOKNWMWMWNKKOl.  :KXOKWOc'';oooc;:cccc:,;::lONWWWWWWWWWWWWNNN    //
//    WWWMMMMNx;;:lodxoodocc:;:oddONMWxcoo::oxkOOKXNWWNKK0xc;;d000KK0kxoooloc...'.',cllc::oOXWWWWWWWWWWWNN    //
//    MMMMMMMXc',;lddddoooooooodkxkXNKO0XNNWWNNK0kxdkKXXXNWWNXKKXXNNWWNNKkddl. .;lclolc:;;;;cokKNWWWWWWWNN    //
//    MMMMMMWO:;;cdkkOOOOkxxdlccx0OO0KNMMMMMWWWNNWKdcdOKXNWNKKNWMMMWWWWWWNKOx;..,lo:;;,;;;:;;co0NWWWWWWWWN    //
//    MMMMMMXkdl:cdoooodoccllclloO0OKWMMMWWWNNWWWMW0olok0KK0KWMMWWNNNWWWMMXko' ..';,';coolo:'lKWWWWWWWWWWW    //
//    MMMMMWXXKxoododdoooooodolocoO0KMMMWWWWWWMMMMXkodxkO00OXMWNNWWWMMMMWKd;.  ..,ldkkkkxlc:;:oKWWWWWWWWWW    //
//    MMMMMMMMXdoxxxkxxdolc:cloxc,dKKKNWWWWMMMMWX0kxkKNWWWNK0XNWWMMWWNKOo;..',:loxkkOkdl:;:codlo0WWWWWWWWW    //
//    MMMMMMMMXdclccclloocldllddc,;d0XK0KKKKKK0kodOXWWMWWK0NWXK000Okdl:,;;':ooxOOxolol:clcoddol:lKWWWWWWWW    //
//    MMMMMMMMNkdolcldddkxddl:coooo:lONWNXXKKXXX0kOKXNX0kkKWMXxloddocclloxlldlloo:,,cllxkdc::;;::dXWWWWWWW    //
//    MMMMMMMMXdcloddxkoollloooxxoodxoo0WMMWWWX0K0kkkkxddkXWXdcoxxkkdcccloc::,',;:::lddool;;loddcl0WWWWWWW    //
//    MMMMMMMNk::clccoddkkxdlc:lloxxkkl;oONWMMN0kOOOOkoloxXKl:c:c:;:c,;;,;:;:lclolool:,,;codxxxx:;xNWWWWWW    //
//    MMMMMMXdcoxkkxlloxkxlcclododkxolcclcokXWMWXK00K0xdx0Xd'';ldo:';c::coxolxxddddxd:;loxkxdocc:;oXMWWWWW    //
//    MMMMMXd:lolcc;';odlodkOOOkocc:coxxxxo::d0NWWNKXXOdoodd;;oxdol:codddxOkddkxddddxdccllll:::lddxKWWWWWW    //
//    MMMMWk;,,,'.    ,ccdOOOOko::lodkxdl:;:;',lkKKKNWKxoccdlldol:cccoxkxxkkxdxxdlllclc::cloodxkxdoOWWWWWW    //
//    MMMMNOxkKKK0x:.  ,lxkdollldxxxolc:c:::;,;:oOKKNWKOkdc:::c;,',;:oxxxooxollolcccc::cokkOkxdoccl0WWMWWW    //
//    MMWNXNWMMMMMMWKo'..coccoxkkxdlcclodoc,'',;:dO0XNK00kl:,'..,cllcclccccloodxdodxxxl;lkxdoc::odoOWMMMWW    //
//    MWNNWMMMMMMMMMMW0c. ,okkkxoccloddoc;;,'';clok0KNNKK0xol;..coooc:::coxxkOO00OkxdooccolccldxkxlxNMMMMW    //
//    WNWMMMMMMMMMMMMMMNd. .,ll:cdkkoc:c::clodool:lkKWMXK0Oxdd;.,cc,';:ldxkkxxxxkOxdl:;clldxxkkkxdcl0WMMMM    //
//    NWMMMMMMMMMMMMMMMMNx.   .,codl:cldxdddoolccloOXMMNKK0xxkx:'.'';lccllc:;:c:clodlclxxodxddol:;;lxKWMMW    //
//    NMMMMMMMMMMMMMMMWNWWx.   .:::cloooccllc:,'':oONWWNXKOo;lkkl..;llc;',..:ooc:lkOxdddolcllc:loccdolONWW    //
//    MMMMMMMMMMMMMMMMWXXWWx.  .;lccccol;cool,','',dXWWXKXKk,.lkOxc:llc,..;,:cc::dOkdolcll:;:llll::kXKKNWW    //
//    MMMMMMMMMMMMMMMMMWXNMNo. .;dxkkxxxooxxc',:;,;xKNKdox00l.'oO0Okxoc;':oc;''.'lxkxo;':ll;;coddl:dNMMMWW    //
//    MMMMMMMMMMMMMMMMMWXNWM0,..'loxxxxkxoxdl:ccc::x0xo:;:lxd;.:k000K0Oxoc::;..  ..,;;'......lOXWNK0KNMMWW    //
//    MMMMMMMMMMMMMMMMMWXXWMXl..'okxxxddollol;:;,,;dKkc;;,:cl:.'xKKKKXXXXKkdlc.              .:ONWNWWWWMMW    //
//    MMMMMMMMMMMMMMMMMWXKWMWd. 'lxO000OOOOkdddc:c:cONOoc:cxkc.'kNXXXXXNNNNNNXo.               'kWNNMMMMWW    //
//    MMMMMMMMMMMMMMMMWNKKNMWo. .;ododdxxkkook0xc,;;l0WNXXNWXl'lKMWWNNWWWWWWWW0'                'ONNWMMMWW    //
//    MMMMMMMMMMMMMMMMWXKKNMK:.  .:ooooodxxdxxkOd:clloOWMMMMXo:OWMMWNWMMMMMMMMK;                 ;0NWMMMWW    //
//    MMMMMMMMMMMMMMMWXKKKXKo...  .':llloxkOOxodxol::,cOKNWW0lxNWNXXXWMMMMMMMMK;                  lKNMMMWW    //
//    MMMMMMMMMMMMMMWWklool;...... ...';cloodddxoc;,;cc::lOXkxNMMNK0XWMMMMMMMMO.                  .xNMMMWW    //
//    MMMMMMMMMMMMMMWNKo,............  .';:cccc:;'':oxd:,',ld0NNWWXKKNWMMMMMMWo                    cXWMMWW    //
//    MMMMMMMMMMMMMMWNWW0:.....   ...    ......:dxk0XNWXKOdoox0XNWWNKKXNWMMMMO'                    :KNMMMW    //
//    MMMMMMMMMMMMMMNNWMW0c....  ...     ...   .;kNMMMMMMMMMWNNNWMMWXKXNNNWW0;                     oXNWMMM    //
//    MMMMMMMMMMMMMWNNMMMM0;........      ....   .;xXWMMMMMMMMMMMMMWN00NNNXk'                     .OWNNMMM    //
//    MMMMMMMMMMMMMWNWMMMMW0c.......               .'ckKNNMMMMMMMMMWWKkO0kc.                     .oNMNNMMM    //
//    MMMMMMMMMMMMMWNWMMMMMMWk;.....                   .',coxO0KKKK0Odc,..                       :KWWWNWMW    //
//    MMMMMMMMMMMMMWWWMMMMMMMMKc....     ......  ...          .......                           :0NNWMNNMW    //
//    XXXXXXNXXNNNNNNNNNNWWWWWNk'..     ..                                                     :0NNNWMWWMM    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract D0LC3 is ERC1155Creator {
    constructor() ERC1155Creator("DEATH of DOLCE", "D0LC3") {}
}