// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0P3N 3D1T10NZ
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNklldOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNO:';:;,;:lx0NWMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX00XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMXo';oxkkxdl:;;;cokKNMMMMMMMMMMMMMMMMMMMMWKo:cd0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0:';:cldOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMX:.lkkkkkkkkxxoc;,;:lx0XWMMMMMMMMMMMMMMNx,.;;,';cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk,,oxdoc:;;:cok0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWx';xkkkkkkkkkkkkxdl:;;;cokKNWMMMMMMMMKc.;okkxdl:,',cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO''okkkkkkxdol:;;:coxOXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMK;.lkkkkkkkkkkkkkkkkkxol:;;:ldKWMMMMWd.,dkkkkkkkxdl:,',:oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc'lxkkkkkkkkkkkxdlc;;;:ldkKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNl.;xkkkkkkkkkkkkkkkkkkkkxdo:.;0MMMMMO''okkkkkkkkkkkxdl:,',:okKWMMMMMMMMMMMMMMMMMMMMMMMMMMMM0;.lxkkkkkkkkkkkkkkkxdoc:;;:cox0XWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMO'.lkkkkkkkkkkkkkkkkkkkkkkkxc.lXMMMMX:.ckkkkkkkkkkkkkkkkdoc,',:okKNMMMMMMMMMMMMMMMMMMMMMMMM0, .lxkkkkkkkkkkkkkxxkkkkxxol:;;;:ldkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMNl.;xkkkkkkkkkkkkkkkkkkkkkkkx;'xWMMMWd.;xkkkkkkkkkkkkkkkkkkkxoc;,,;lkKNMMMMMMMMMMMMMMMMMMMMXl. .lxkkkkkkkkkkxl;:lodxkkkkkkxdlc:,,xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMO'.okkkkkkkkkkkkkkkkkkkkkkkko',0MMMMO'.okkkkkkkkkkkkkkkkkkkkkkkxoc;,,;lxO0NWMMMMMMMMMMMMMMMXl. .lxkkkkkkkkx:';oxxxxkkkkkkkkkkkd,,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.;xkkkkkkkkkkkkkkkkkkkkkkkxc.cXMMMX:.:xkkkkkkkkkkkkkkkkkkkkkkkxxxdo, .'';lx0NWMMMMMMMMMMMMXc. .lkkkkkkkd;':xkkkkkkkkkkkkkkxdo;.cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'.okkkkkkkkkkkkkkkkkkkkkkkkx;.dWMMWd.,dkkkkkkkkkkkkkkkkkkkkkkkkxdol,.,ooc;,';cxXMMMMMMMMMMMXc. .lkkkkko,'cxkkkkkkkkkkkkkkkkxdc'':odk0XWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc.:xkkkkkkkkkkkkkkkkkkkkkkkko,,OMMM0'.lkkkkkkkkkkkkkkkkkkkkkkkkkkxdl;;::lxxdc..xWMMMMMMMMMMMXc. 'lkkxl''lxkkkkkkkkkkkkkkkkkkkkxdlc;;;;:loxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk'.okkkkkkkkkkkkkkkkkkkkkkkkxl.:XMMNc.:xkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddllxkkx;.dWMMMMMMMMMMMMKc. 'okx:.:xkkkkkkkkkkkkkkkkkkkkkkkkkkxxdoc:;;;:cxNMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc.:xkkkxdxkkkkkkkkkkkkkkkkkkx:.oNMWx.,dkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkx:.,oOXWMMMMMMMMMMK:  'okd,'lkkkkkkkkkxxxxxkkkkkkkkkkkkkkkkkkkxdo,'xWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk'.lxxocoxkkkkkkkdldkkkkkkkkkd,'kWM0,.lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkdl:,',:okKWMMMMMMMK:  'okl',dkkkkkkkkd:'',;;:cllodxxxkkkkkkkkkkko':KMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc..'',cxkkkkkkkx:'lkkkkkkkkkkl':KMNl.;xkkkkkkkkkkkkkxxkkkkkkkkkkkkkkkkkkkkkkkkxdoc;',;lx0NWMMMK:  'ox:.:xkkkkkkkko,       ....',;;:ldkkkkkkx:.dWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.  .cxkkkkkkkkl..:xkkkkkkkkkx:.oNWk.'dkkkkkkkkkkkkkd:;coxkkkkkkkkkkkkkkkkkkkkkkkkkxoc;'';lx0NWK:  'od;.lkkkkkkkkko,              .;dkkkkkdl'.cNMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK: .lxkkkkkkkkd,  ,dkkkkkkkkkkd,'kWK;.,cdxkkkkkkkkkkxc. .';coxxkkkkkkkkkkkkkkkkkkkkkkkkxoc;,';cdo'  'l:.'okkkkkkkkkd,           .,lxkkkxo:..  ;KMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk,'oxkkkkkkkkx:.  .lkkkkkkkkkkko',do;,;,';ldkkkkkkkkkx;.    ..,:ldxkkkkkkkkkkkkkkkkkkkkkkkkxdl:,'.   .. .;dkkkkxdoc;'..;dolc,. 'cxkkxdc,.     .dWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd',okkkkkkkkkko.   .:xkkkkkkkkkkd:,:ldxkxl,.:xkkkkkkkkkd,        ..,:cldxkkkkkkkkkkkkkkkkkkkkkkkxdo:,..   .cdoc;,,,;:ll,'xNNO:':dkkxl;.        .dNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMN0dxkl';dkkkkkkkkkkx;    .;xkkkkkkkkkxxdxkkkkkko'.lkkkkkkkkkkko'             .';coxkkkkkkkkkkkkkkkkkkkkkkkxdoc;'.......:xkkkkd;'cc,:dkxo:'.       .,oKWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMW0d:,,:::cdkkkkkkkkkkxc.  .;''okkkkkkkkkkkkkkkkkkd;..lkkkkkkkkkkkkl..;:'.           .';coxxkkkkkkkkkkkkkkkkkkkkkkkxoc;'...lkkkkkkd;.;oxkxo;'....    .;okOXWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWKx:,;cdxkkkkkkkkkkkkkkkd'   .,',okkkkkkkkkkkkkkkkkx:.  ;xkkkkkkkkkkkxc.cKX0dc,.           ..,:ldxkkkkkkkkkkkkkkkkkkkkkkko,.;dkkkkkkkxdxkkkkxxxddoolcc:::;;,;dKWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMKl,,:oxkkkkkkkkkkkkkkkkkxl,,;:cldxxkkkkkkkkkkkkkkkkxl.   .okkkkkkkkkkkkx:.oNMMMN0xol,.          ..,:oxkkkkkkkkkkkkkkkkkkkd;.;dkkkkkkkkkkdlcclodxxkkkkkkkkkkkdc,,l0WMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMM0,.cdxkkkkkkkkkkkkkkkkkkkxxxkkkkkkkkkkkkkkkkkkkkkkko'    .:xkkkkkkkkkkkkd,.xWMMMMMMMNKko;.          'okkkkkkkkkkkkkkkkkkd,..lkkkkkkkkkkkx:. ...'',;:clodxkkkkkxl;,cONMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWO:'.',cdkkkkkkkkkkkkkkkkkkkkkkkkkkkxxkkkkkkkkkkkkx;.   ..,dkkkkkkkkkkkkko',OWMMMMMMMMMMWXOo:'.     'okkkkkkkkkkkkkkkkkd,  .;xkkkkkkkkkkkx:.          ..:dkkkkkkxo;,:kNMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMKl.  .:xkkkkkkkkkkkkkkkxxxdoolc:;;;cdxkkkkkkkkkkkx:.  :x,.lkkkkkkkkkkkkkkl';0MMMMMMMMMMMMMMWX0dc'. 'dkkkkkkkkkkkkkkkko,    .cxkkkkkkkkkkkx:.           .:xkkkkkkkxd:,;dXWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMK;  .cxkkkkkkkkkkkkkkd:,'....     'okkkkkkkkkkkkkkd, ,0Nl.;xkkkkkkkkkkkkkxc.cXMMMMMMMMMMMWMWWWWWXd.'dkkkkkkkkkkkkkkko'      .okkkkkkkkkkkkx:.....       .cxkkkkkkkkkdc,;o0WMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWd.'lxkkkkkkkkkkkkkkx:.           .okkkkkkkkkkkkkkkl.;KWk.'okkkkkkkkkkkkkkx:.oNW0xollllcccc::::::,.,dkkkkkkkkkkkkkko'    .,..,dkkkkkkkkkkkkxc.:OKOxdlc;. .lxkkkkkkkkkkxl;,lOWMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNx',okkkkkkkkkkkkkkkkl...          .ckkkkkkkkkkkkkkkx:.oNK;.cxkkkkkkkkkkkkkkd;'xO, .,:::c:c:. 'ccllldxkkkkkkkkkkkkko'    .,:'..:xkkkkkkkkkkkkxc'cXMMMMMNx. .okkkkkkkkkkkkxo;,ckNMMMMMM    //
//    MMMMMMMMMMMMMMMMMXo';dkkkkkkkkkkkkkkkkd:;loc:,'. .cdc.;xkkkkkkkkkkkkkkkd,'kNo.,dkkkkkkkkkkkkkkkd,....:xkkkkkkkc.,dkkkkkkkkkkkkkkkkkxl'    .;''cl;'lkkkkkkkkkkkkkxc'cKWNXKOd, .,dkkkkkkkkkkkkkxo:';kWMMMM    //
//    MMMMMMMMMMMMMMMMKc.'dkkkkkkkkkkkkkkkkkdodkkkkkxl.;KM0,'dkkkkkkkkkkkkkkkko';0O'.lkkkkkkkkkkkkkkkko..;odkkkkkkkko'.lkkkkkkkkkkkkkkkkxl.    .oc'cxkd:;okkkkkkkkkkkkkxl',c::;;;::coxkkkkkkkkkkkkkkkx;.oNMMMM    //
//    MMMMMMMMMMMMMMW0;...,cdkkkkkkkkkkkkkkkkkkkkkkkkl.:XMXc.lkkkkkkkkkkkkkkkkxc.l0c.:xkkkkkkkkkkkkkkkxl:okkkkkkkkkkd;.:xkkkkkkkkkkkkkkxl.    .xk,,dkkkdccxkkkkkkkkkkkkkxdoodxxxkkkkkkkkkkkkkkkkkkkkxc.,0MMMMM    //
//    MMMMMMMMMMMMMWO,.''....;oxkkkkkkkkkkkkkkkkkkkkkc..:lc'.:xkkkkkkkkkkkkkkkkx;'dd.'okkkkkkkkkkkkkkkkxxkkkkkkkkkkkxc.,dkkkkkkkkkkkkkxl.    .xXl.cxkkkkdloxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkl. .,kWMMM    //
//    MMMMMMMMMMMMNx',oxo:'.,,';lxkkkkkkkkkkkkkkkkkkx:.  .,:,;dkkkkkkkkkkkkkkkkko',d;.cxkkkkkkkkkkkkkkkkkkkkkkkkkkkxdc..okkkkkkkkkkxdl:.    .kWO,,dkkkkkkxdxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkko'   .oNMMM    //
//    MMMMMMMMMMMNo';dkkkkxdxxo;',cdxkkkkkkkkkkkkkkkx:.  .:xdldkkkkkkkkkkkkkkkkkxc.,'.;xkkkkkkkkkkkkkkkkkkkkkkkkkkko,...:xkkkxdoc:,'..     .kWNc.lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkko'    cXMMMM    //
//    MMMMMMMMMMXc':xkkkkkkkkkkkdc,':oxkkkkkkkkkkkkkd,  ..;xkkkkkkkkkkkkkkkkkkkkkd,...'okkkkkkkkkkkkkkkkkkkkkkkkkkko..'.,ll:;'..          'kWWk';xkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdoc'    :KMMMMM    //
//    MMMMMMMMW0:'cxkkkkkkkkkkkkkkdl;';lxkkkkkkkxoc,.. .,'.;loxxkkkkkkkkkkkkkkkkxc.;dl,cxkkkkkkkkkkkkkkkkkkkkkkkkxxl...  .               'OWMXc.lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdl:,..     ;0MMMMMM    //
//    MMMMMMMWO;'lxkkkkkkkkkkkkkkkkkxo;',cdxxoc;'.     .dd.  ..,:coxkkkkkkkkkkkko''okxlcdkkkkkkkkkkkkkkkkkkkkxoc;,..                 .,:oKWMWk';xkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdoc;'.         'OMMMMMMM    //
//    MMMMMMNx,,okkkkkkkkkkkkkkkkkkkkkxd:..''.         .kO.       ..,:coxxkkkkkd;.cxkkxddkkkkkkkkkkkkkkkkkkkxl.                .';ldOKNWMMMMX:'okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxol:,..            'kWMMMMMMM    //
//    MMMMMNo';dkkkkkkkkkkkkkkkkkkkkxdl;'.           .,oXK:            ..,:loxxc.;dkkkkkkkkkkkkkkkkkkkkkkkkko.           ..;cdkKNWMMMMMMMMMWx':xkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdl:;'.             .;lxKWMMMMMMMM    //
//    MMMMXl':dkkkkkkkkkkkkkkkkkxdl:'.           .'cx0NMMWXOdc,.            ..'.'okkkkkkkkkkkkkkkkkkkkkkkkkd'       .,:ox0XWMMMMMMMMMMMMMMMK:'okkkkkkkkkkkkkkkkkkkkkkkkkxoc;'..            .':oOXWMMMMMMMMMMMM    //
//    MMMNo.'lxkkkkkkkkkkkkkxdl:,.           .':d0NWMMMMMMMMMMNKkdc,.          .lxkkkkkkkkkkkkkkkkkkkkkxdlc,.   .lxOXNWMMMMMMMMMMMMMMMMMMMWd':xkkkkkkkkkkkkkkkkkkkkxdl:,'.             .;lx0NWMMMMMMMMMMMMMMMM    //
//    MMMWKd:..;coxxkkkkxdo:,..           .:d0NWMMMMMMMMMMMMMMMMMMMNKOdc,.    .cxkkkkkkkkkkkkkkkkxdoc:,..      'OWMMMMMMMMMMMMMMMMMMMMMMMMK;'okkkkkkkkkkkkkkkkkxoc;'..            .'cdOXWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMXl.   ..;col:,..           .:oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkd:..cxkkkkkkkkkkxxol:;'..          .xWMMMMMMMMMMMMMMMMMMMMMMMMWd.:xkkkkkkkkkkkkxdl:,..             .;lkKNWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMWd.        ..           .;oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk'.cxkkkxxdlc;,..                lNMMMMMMMMMMMMMMMMMMMMMMMMMWk;':oxkkkkkxdoc;'..            .,cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMWXkl,.              .;okKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX: .;lc:,'..                ..,:xXMMMMMMMMMMMMMMMMMMMMMMMMMMMM0, .;lddl:,..            ..;okKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMNKxl,.      .,lkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;                    .';ldOKXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.   ...             .,cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNKxl;;cxKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;             ..,cdkKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:.             ..:okKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.      .,:ox0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc.       .,lx0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx,';ldOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo,.':okKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract O3 is ERC1155Creator {
    constructor() ERC1155Creator("0P3N 3D1T10NZ", "O3") {}
}