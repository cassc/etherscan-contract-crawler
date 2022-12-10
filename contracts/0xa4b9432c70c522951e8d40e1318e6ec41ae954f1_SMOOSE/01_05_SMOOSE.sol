// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Seasonal Moose
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    .,cc::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::c:::::::::::::::::::::::cclc'.    //
//    .;kl;oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo;lx;.    //
//    .;x:cXNkdddddddddddddddddddddddddddddddddddooooooooooooodddddddddddddddddddddddddddddddddddokNX::x;.    //
//    .;x::XKc.'....''''''''..............'',;cllodddxxxxxxxddoolc:,,''..''...''.''''''''..'..'''.cXX::x;.    //
//    .;x::XKc''''''''''''''''''''''',:ldxOOkkkkxxddooooooooodxxkOOOOOxdl:,''''''''''''''''''''''.cXX::x;.    //
//    .;x:cXKc''',,'''',;'''''''';ldkOOkxol:,,'''''''''''''''..''',;:loxOOOkdl;'''';;''''''''''''.cXX::x;.    //
//    .;x::XKc'.,ko.'':Ox;''',cdO0Oxl:,'''''''''''''''''''''''''''''''''',:oxO0Od:;ko.'''',:,.'''.cXX::x;.    //
//    .;x::XKc'.,Ox'.'xKkd,;dO0ko:''''''''''''''''''''''''''''''''''''''''''',:okOdOd',''.o0c..ck::XX::x;.    //
//    .;x:cXKc...dKc.;00kdlkxl;'''''''''''''''''''''''''''''''''''''''''''''''''',;kx:xk;:K0:.,OK::XX::x;.    //
//    .;x:cXKlo:.:KKdkNkcol;ok:.''','.''''''''''''''''''''''''''''''''''''''''''''.l0:,olkWk''dNx':KXc:x;.    //
//    .;x:cX0cxK:.xWMMMXkc.'ONl.'.cOl;;'''''''''''''''''''''''''''''''''''''':;'''.:KKdd0WXc.lXO;.cKXc:x;.    //
//    .;x:cXK:;OK::KMMMNo..'xWo.''dNxxd'''''''''''''''''''''''''''''''''''''cKx'''.:XMMMMWk:dXk;..cXX::x;.    //
//    .;x::XK:.,kKdOMMMX:.'.lNO,.,OXdOx.'''''''''''''''''''''''''''''''''.coxWx''''xWMMMMNxkXd,.'.cKX::x;.    //
//    .;x::XK:'''lkKWMMWx''.;0W0dOWWXNo.''''''''''''''''''''''''''''''''.'xxdWk'.'dNMMMMXkkkc'.''.cKX::x;.    //
//    .;x::XK:'''.,oKWMMNx;..xMMMMMMMXc.''.'''''''''''''''''''''''''''''.'kX0WXockNMMN00Oxo;.''''.cXX::x;.    //
//    .;x::XK:.''''lxx0WN0kodKMMMMMMM0;.'.:l,'''''''''''''''''''''',''''.;KMMMMMWNK00kdoccOd,''''.cXX::x;.    //
//    .;x::XK:.'''cKO;,lx000OOO0XWMMMXl.'.;dxc.,d:.'''''''''''''.;kx,''.:OWMWNK00Okdl:'..;OXo''''.cXX::x;.    //
//    .;x::XKc.'',kXl'''.,cdkO00XWMMMMXd:'..cKkcll''''''''''''.'l0O;':lx0000Okdool;'.''''.cKKc'''.cXX::x;.    //
//    .;x:cXKc.''lXk,''''''..,:clooxkO0KKOkx0WMW00x;'.'..''',:lONMKk0NWKdlccc:,..''''''''''oNk,''.cXX::x;.    //
//    .;x:cXKc'',OXl'''''''''''''....'',;:oO0OOO0KKOkkkkkO00KNMWNX0kxol:,'..''''''''''''''';OXl''.cXX::x;.    //
//    .;x:cXKc''cXO;.''''''''''''''''''''.,lxkkkOOkxdllxOOO0KOooxdOo'.''''''''''''''''''''''oNk,''cXX::x;.    //
//    .;x:cXKc.'dNd'''''''''''''''''''..'''...,;cdOkddxO0OOXXxo0kxKd'''''''''''''''''''''''.:0K:'.cXX::x;.    //
//    .;x:cXKc.,kXl''''''''''''''''''.;x000Okxk0XWMMMWKOkdxNxlKMWXl''''''''''''''''''''''''',kNo'.cXX::x;.    //
//    .;x:cXK:.;OKc.'''''''''''''''''.lNMMMMMMMMMMMMMNOxxkXWOlxOkddl'''''''''''''''''''''''''xNd'.cXX::x;.    //
//    .;x::XK:.;00:.'''''''''''''''''.,dKNNNMMMMMMMMMKl:ckWMMXl,xNMNx;'''''''''''''''''''''''dNx'.cXX::x;.    //
//    .;x::XK:.;0K:.''''''''''''''''''''':oKWMMMMMMMWXXWWWMMMWo,0MMMMXo''''''''''''''''''''''dWx'.cKX::x;.    //
//    .;x::XK:.,OXc.''''''''''''''''''.':kNMMMMMMMMMMMMMMMMMMWdlXMMMMMWk;''''''''''''''''''''xNd'.cKX::x;.    //
//    .;x::XK:.'xNo'''''''''''''''''.'ckNMMMMMMMMMMMMMMMMMMMMWd,OMMMMMMWKd;''''''''''''''''.,ONl'.cKX::x;.    //
//    .;x::XK:.'oNx,''''''''''''''''cOWMMMMMMMMMMMMMMMMMMMMMW0,.dMMMMMMMMMXkl;'''''''''''''.:K0:..cXX::x;.    //
//    .;x::XK:'':00:.''''''''''''''oNMMMMMMMMMMWWMMMMWWMMMWXd'.:KMMWWMMMMMMMWXOl,'''''''''''dNx,'.cXX::x;.    //
//    .;x::XK:'''xNd'''''''''''''.lNMMMMMMMMMWKkKNOdl;;lol:,,:kNMMMXkKMMMMMMMMMWO:.'''''''';0Xc''.cXX::x;.    //
//    .;x::XK:.''cKK:'''''''''''..xMMMMMMMWXkl:ollxx;':ccldOKO0MMMMWOo0MMMMMMMMMMKc''''''''dNx,''.cXX::x;.    //
//    .;x::XKc.'''oXk,'''''''''''.lNMMMMMWOxo'.'.lNMOckNXXWMWxxMMMMMWOdXMMMMMMMMMMXo''''''lX0;'''.cXX::x;.    //
//    .;x::XKc'''',kXd,''''''''''.'dNMMMXkk0l.'.:KMMNllOdo0MMxdNMMXKWNdxWMMMMMMMMMMNd'''':0Kc''''.cXX::x;.    //
//    .;x::XKc''''';kXd,'''''''''''':dxl:ld:.'.'kMMMMx:kXolXMOdKMM0ckWkdNMMMMMMMMMMWk,.':OXo'''''.cXX::x;.    //
//    .;x::XKc.''''';OXd,''''''''''''...''.'''.:XMWWM0:xMXolKXdkWMWocXOdXMMMMMMMMMNO:'':OXo''''''.cXX::x;.    //
//    .;x::XKc.'''''';kXk;''''''''''''''''''''.cX0kNMX:dMMWOoko:OWMdcXXKWMMMMMMMWKl,''c0Kl'''''''.cXX::x;.    //
//    .;x::XKc.''''''',oK0c'''''''''''''''''''.,xldWMKcxMMMMNxdkdkXodWMMMMMMMMMXx;'',oK0c''''''''.cXX::x;.    //
//    .;x::XKc.'''''''''lXKc'',;;''''''''''''''',,xMWdlOOOXMMWNW0oldXMMMMMMWX0d:''':kXx;'''''''''.cXX::x;.    //
//    .;x::XKc''''''''''lXXc.,o0Oc,'''''''''''''..oKdlKXOldWMMMM0:lXMMMWKkdc:,''';dK0l'''''''''''.cXX::x;.    //
//    .;x::XKc.''''''''.,lO0o;:dkOOo:;,''''''''''.:c'oNMM0lOMMNkokNNKOdllc,'''';o00o;''''''''''''.cXX::x;.    //
//    .;x::XKc.''''''''''.'cddoccldxO0oooc;,'''''',,.'dNMWlcKOlcodoc:lllkKd,':x0Oo;''''''''''''''.cXX::x;.    //
//    .;x:cXKc.'''''''''''''.':oxxolclodkxxdollc;:,.,,:OXk,.;lllldxkxkkl:lddkOxc,''''''''''''''''.cXX::x;.    //
//    .;x:cXKc'''''''''''''''''',lkkkxdl::coookOkOl';dxc,''.'d0kdloo:;odxkOxl;'''''''''''''''''''.cXX::x;.    //
//    .;x:cXKc'''''''''''''''''''''';cdkkkxdolccll:,';:,'''',:cclloxkkkxl:,'''''''''''''''''''''''cXX::x;.    //
//    .;x:cNWKOOOOOOOOOOOOOOOOOOOOOOOxl;,;cloxxxxxxxxxxxxxxxxxxxxdol:::lokOOOOOOOOOOOOOOOOOOOOOOOOKWX::x;.    //
//    .;x:'odoodoooooooooooooooooooooool;,........'',,;;;,,,''.....',:loooooooooooooooooooooooooooool':x;.    //
//    .;kkllllllllllllllllllllllllllllllllolllllllloooooolllllllllllllllllllllllllllllllllllllllllllllxk,.    //
//    .':cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc;'.    //
//    ....................................................................................................    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SMOOSE is ERC1155Creator {
    constructor() ERC1155Creator("Seasonal Moose", "SMOOSE") {}
}