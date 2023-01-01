// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dead Is Dead OE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//                                                                                   //
//       ___              __  ___  _        __      ____        _     __             //
//      / _ \___ ___ ____/ / / _ )(________/ ___   / _____ ____(____ / /___ __       //
//     / // / -_/ _ `/ _  / / _  / / __/ _  (_-<  _\ \/ _ / __/ / -_/ __/ // /       //
//    /____/\__/\_,_/\_,_/ /____/_/_/  \_,_/___/ /___/\___\__/_/\__/\__/\_, /        //
//       ___              __  ____      ___              __            /___/         //
//      / _ \___ ___ ____/ / /  ____   / _ \___ ___ ____/ /                          //
//     / // / -_/ _ `/ _  / _/ /(_-<  / // / -_/ _ `/ _  /                           //
//    /____/\__/\_,_/\_,_/ /___/___/ /____/\__/\_,_/\_,_/                            //
//      ____                 ____   ___ __  _                                        //
//     / __ \___ ___ ___    / _____/ (_/ /_(____  ___                                //
//    / /_/ / _ / -_/ _ \  / _// _  / / __/ / _ \/ _ \                               //
//    \____/ .__\__/_//_/ /___/\_,_/_/\__/_/\___/_//_/                               //
//        /_/                                                                        //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0dooooooooooooookNMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMXkxxdddl:;;;;;;;;;;;;;;coxxxXMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWKkkkd:,,,,;xWWMWMMWMMMMWWWW0c,,;okkkKWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWXOl,''cKWWWWWWMMMMMMMMMMMMMMMMWWWXo'''ckKWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWXOl,dXNNNMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNXx;:kXWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWNOc,xKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXk::kNWMMMMMMMMMMM    //
//    MMMMMMMMMMMMM0;,dKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKk;,kMMMMMMMMMMM    //
//    MMMMMMMMMMMMWk..OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,.dWMMMMMMMMMM    //
//    MMMMMMMMMMMO:cdONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdc:kWMMMMMMMM    //
//    MMMMMMMMMMWd ,KMMMMMMMMMKoc:c::ccxNMMMMMMMMMMMMMMMMNxccc:cc:oKX: lNMMMMMMMM    //
//    MMMMMMMMMMWd ,KMMMMMMM0o;      'cllxNMMMMMMMMMMMMNxc.     .:llc. lNMMMMMMMM    //
//    MMMMMMMMMMWd ,KMMMMW0o,        'llccooxXMMMMMMMXxc.       .coc:. lNMMMMMMMM    //
//    MMMMMMMMMMWd ,KMMMMNl            :Xk. .kMMMMMMMk.           .kX: lNMMMMMMMM    //
//    MMMMMMMMWKko,lXMMMMNl            :Xk. .kWKkkkKWO.           .kX: lNMMMMMMMM    //
//    MMMMMMMMWl.:KWMMMMMNl            :XO. .oOc'''cko.           .kX: lNMMMMMMMM    //
//    MMMMMMMMNl :XMMMMMMWd.          .:Ox,....cOKXd....         .,xO, lNMMMMMMMM    //
//    MMMMMMMMNl :XMMMMMMMNKo.       ;ko,cOKk,..,dKd.,kk,       .dx:.  lNMMMMMMMM    //
//    MMMMMMMMNl.:KWMMMMMMMMN0o.     .'ckKWMWK00Ol,cOKWWKk;     ..;xk, lNMMMMMMMM    //
//    MMMMMMMMWXOo;lXWWWWWMMMMN0kkkkkkOKWMMMMMMMWXOKWMMMMWKOkkkkkk0NX: lNMMMMMMMM    //
//    MMMMMMMMMMMXko:;;;;:kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo:lxKWMMMMMMMM    //
//    MMMMMMMMMMMMMXxc.   .:cccccccccccccdXMMMMMMMMMMMMMMWxccccccccldKMMMMMMMMMMM    //
//    MMMMMMMMMMM0olllllllllllllllc. .clllllllllllllllllllllllll; .kMMMMMMMMMMMMM    //
//    MMMMMMMMW0dlcccoKMMW0dooooool. lWMMKoccc:.          ,ooooooccldKMMMMMMMMMMM    //
//    MMMMMMMMNl :XXkxxxxd,   .,;;,. lWMMMMMMMX: .;;;;;;;;;;;;. .ldc:lxKWMMMMMMMM    //
//    MMMMMMMMWl :X0c,,,,,,'. .okkd' ;kkk0WMMMX: ,xkkkkkkkkkkko;,,c0X: lNMMMMMMMM    //
//    MMMMMMMMWd'cO0OOOOXNWNx,.''''..'''':k000kc..'. ..'''''''cxOOO0Oc'dWMMMMMMMM    //
//    MMMMMMMMMXOo,'''';xKKK0OOOOOOOOOOOOd;'...dXXXo .dOOOOOOOl......oXWMMMMMMMMM    //
//    MMMMMMMMWo.cO0OOOx;......''''...'''cOKx..dWMMd. .'''''''. .od'.oXWMMMMMMMMM    //
//    MMMMMMMMNl :X0:'''.     .dOOx' ;kOO0WM0,.dWMMd..oOOOOOOkc...;xkc'dWMMMMMMMM    //
//    MMMMMMMMNl :XXOkkkkkkk:  .,,'. .',,lKM0'.dWWWd. .,,,,,,,cxkkOXX: lNMMMMMMMM    //
//    MMMMMMMMWKxl:;;;;;;;;;.             ,;,. .;;;.          .,;;;;:lxKWMMMMMMMM    //
//    MMMMMMMMMMMKdooooooooooooooooooooooooooooooooooooooooooooooooodKMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract DIDOE is ERC1155Creator {
    constructor() ERC1155Creator("Dead Is Dead OE", "DIDOE") {}
}