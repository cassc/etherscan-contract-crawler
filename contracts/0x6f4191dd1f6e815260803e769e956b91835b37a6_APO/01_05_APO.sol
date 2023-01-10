// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: YungContent NFToys
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0OOOOOO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxdolllccccccccllllodx0XWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMN0xlcc:codxkkOOOOOOOOOkxdolc:clokKWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMW0dc:coxxkOOOOOOOOOOOOOOOOOOOOOOkdlc:lxKWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNkc;cdxkOkxkOOOOOOOOOOOOOOOOOOOOOOOOOOko::o0WMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMW0c;lkOOkkkxdddollllccccccccclllooddxkkOOOOxc;oXMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNx;:ddocc:::::::::ccccclllllccccc:::::::::clodo;:0WMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNd..;:::clodxkkkkOOOOOOOkOOOOOOOOOkkkkkkxdlc::::,.,OWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMW0l;;coxkkkkkOOOkkOOkOOOOkkkkkOOOOOOkkOOkkkOkxkkkxoc,;dXMMMMMMMMMMMM    //
//    MMMMMMMMMMMNx;:dkxkkkxxkkOOOOkOkkOOOkkkOOOOOOOOOOkOOkxxkkkxkkkxkko;:0WMMMMMMMMMM    //
//    MMMMMMMMMMWd,ckkkxkOkxkkOOOkkkkxxxddddddddddxxxkkkkOkkxkkxxkkkkxkOx;;0MMMMMMMMMM    //
//    MMMMMMMMMM0;:kOkxxkOkddolc::::::::::::::::::::::::::ccloxxxkkkkxkkOd,lNMMMMMMMMM    //
//    MMMMMMMMMMk,lkOkdlc:;;;,''''',;:cldxkkkkkkkkxxol:;,'''',;;;:clddxkOx;:KMMMMMMMMM    //
//    MMMMMMMMMMO,;l:,....,,'...........'okkkkkkkko;...........';;...',:oo,cXMMMMMMMMM    //
//    MMMMMMMMMMNo..  .......,:coodoooc:cdkxxkkkkkd:,;cclllc:;'........ ..;OWMMMMMMMMM    //
//    MMMMMMMMMMNd.  .....':lllc:;;;:cdkkkxc:dkkkkkdc:c:;;;:lodo;..... . .cKWMMMMMMMMM    //
//    MMMMMMMMNx;..  ....lxl::c,.  .'coxkko';xkkkkkdldo,   .,;cxxdl'..  ...,oKMMMMMMMM    //
//    MMMMMMMWd. ... ...'oxookx;    .lkkkx:'okkkkkkkkxc.   .cddxkkx;.... ....cNMMMMMMM    //
//    MMMMMMMWd. .... ...;dkkkd,  ..;okkko';xkkkkkkkkd,  ..:dkkkkxc..... ....cNMMMMMMM    //
//    MMMMMMMNo. ... .....lkkkx;   ..:xkx:'lkkkkkkkkkd'   ..ckkkkd'.....  ...:XMMMMMMM    //
//    MMMMMMXo. ... .....'okkkkc.    ,xko';xkkkkkkkkkd,    .lkkkkx;..... .....:0MMMMMM    //
//    MMMMMMx. ...  .....ckkkkkd;.  .lkx:'lkkkkkkdclxxc.  .:xkkkkko'....  .....lNMMMMM    //
//    MMMMMMO' ....  ...'okxxxkkxl:cokkd''cdkkkxdc''dkxoc:oxkkxxkkx;...... .. .dWMMMMM    //
//    MMMMMWk' ..... ....cl;;cxkkkkkxo:,. ..:cc:.  .;cdxkkkkkdc;:oo'...... .. .dNMMMMM    //
//    MMMMXo....... .......'okkkkxo:'.                .,cdkkkkxl',;....... .....c0WMMM    //
//    MMMNl......  .......,.,ccc;,.                     ..,:cl:'.;....... ...... ;KMMM    //
//    MMMNl...... ...... .cc'.             ..'..              .';'. ..... ...... ;KMMM    //
//    MMMXc......  .....  .cdl;'..      ..cxKXX0d:.       ..';ll'..  .....  .... ;0MMM    //
//    MWO:. ...... .....  ..,okxdolccclc;;ldxxxxoc;,:cccclldxxc.... ....... .... .;kNM    //
//    Wx. ....... ....... ....:dkkkkkkkkxdl:''',codkkkkkkkkko;.... ........ ........cX    //
//    Wx. ...... ........ ......;oxkkkkkkkkdlccoxkkkkkkkkko:...... ........ ........cX    //
//    MN0xdxOOkdc,................':oxkkkkkkkkkkkkkkkkxoc,...............':lxOOkxdxONM    //
//    MMMMMMMMMMWXOxddxO0Oxc'.......,:::coddxxxxxdolc::;'......:okOOxdodkKWMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWXOkxxk0KXK0xollcccccclloxOXNKOxdxkKWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXKKXXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract APO is ERC1155Creator {
    constructor() ERC1155Creator("YungContent NFToys", "APO") {}
}