// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tasty Noodles
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                                                                                         //
//     0000000000000000000000000000000000000KKKKKK0000000000000000000000000000000000000    //
//    0000000000000000000000000000KKKKKKKKKKKKKKKKKKKKKKKKK000000000000000000000000000     //
//    0000000000000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000000000000000000000     //
//    0000000000000000000KKKKKKKKKKKXXXXXXXXXXXXXXXXXXXKKKKKKKKKKK0K000000000000000000     //
//    00000000000000000KKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKK0000000000000000     //
//    00000000000000KKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKK00KKKKKKK00000000000000     //
//    000000000000KKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXo''',,'.'',,'.lKXKKKKKK000000000000     //
//    00000000000KKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXKKKc ,dkk; ,dxk; ;0KKKKKKKKK0000000000     //
//    0000000000KKKKKKXXXXXXXXXXXXXXXXXXXXXXXKKo,,,. :0XXl :0XXl...',l0KKKKKK000000000     //
//    00000000KK000KKKKKKKKKKKKKKKKKKKKKKKXKo,,cddodo:'oX0kc'oK0k; 'o:,oKKKKKK00000000     //
//    0000000K00l'',,'''''''',,,,,,,,',,,',,cdxOKo'''. :KXXc :KXXl .':dOXXKKKKKK000000     //
//    00000KK0o,:odoodoooooooooooooooodddoodkKKKKkdoo, cKXKc.cKXKc 'o:,oKXXKKKKKK00000     //
//    0000KKKKOxc'''''''''''''''''''''''''',l000Ko''.:x0Xd'cx0Xd'. .':dOXXXXXKKKKK0000     //
//    0000KKKKKKOxxxxxxxxxxxxkkkkkkkkkkkkkkkc''lOko, :KXXl :KXXl 'ooo:,dXXXXXKKKKK0000     //
//    000KKKKKKXXXXXXXXXXXXXXNNNNNNNNNNNNNNN0kxc,''. :0XXl :0KXl ..''cx0XXXXXXKKKKK000     //
//    000KKKKKXXXXXXXXXXXXNNNNNXNNNNNNNNNNNNNNNKkkkkkc'oK0xc'oK0k; ,x0XXXXXXXXXKKKK000     //
//    00KKKKKXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNc :KXXc :KXXl :XNXXXXXXXXXKKKKK00     //
//    00KKKKXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNNNNWNNNNNXc cKXKc cKXKl cXNXXXXXXXXXXKKKK00     //
//    0KKKKXXXXXXXXXXXNNNNNNNNXXNNNNNNNNNNNNNNNNNWNd':d0Xd':x0Xd'cx0XNXXXXXXXXXXKKKKK0     //
//    0KKKKXXXXXXXXXXXNNNNNNXKo,oXNNNNNNNNNNNNWNNWNl :KXXl :KXXl :XNXXXXXXXXXXXXKKKKK0     //
//    0KKKKKXXXXXXXXXXNNNXXKo',:,'oXXXXXXNNWWWWWNWNl :0XXl :0XXl.cKXXXXXKKKKKKKKXKKKK0     //
//    0KKKKKXXXKKKKKXXXNXXd,. ... .,,,,,,,dXNWNWWWN0xc'oKOxc'lKOxc,,,oKd,,'',''oKKKKKK     //
//    0KKKKXXXo'',,,,,dKd,cxxxxxxxxxxxxxxxc,dXNNNNXd,. .,,,. .',,;:::;,:looll' :KKKKK0     //
//    0KKKKXXKc 'lllol:,:d0XXXXXXXXXXXXXXX0xc,'',,,cxxxxxxxxxxxxx:...;ldkkkkx; :KXKKK0     //
//    0KKKKKXKc ;xkkkOxo:,dXd,,,,,,,,,,,oKKKc  ;xxk0XXXXXXXXXXXXX0kxxc'cxc'''cxOKKKK00     //
//    0KKKKKXXOx:'cxkkkOdl:,cdddddddddddc'',cxx0XXXd,,,,,,,,,,,,,oXXN0xc':dxxOXXKKKKK0     //
//    00KKKKXXXXOd:'''cxc'cxO0o,,,,,,,o0: ,x0XNXXd;cxxdddddddddddc,oXXN0xc'oXXXXKKKKK0     //
//    000KKKKXXXo'cdxx:.:dOKo,cxxxxxxxc'. cXNXKd,cxOKo,,,'',,',oKOxc,dXXXl :0XXXKKK000     //
//    000KKKKKXK: cKXNc cKo'cx0Xd,,,o0: ,d0Nd''cxOKo,cxxxdxxxxxl,oKOxc'dX0xc'oKKKKKK00     //
//    000KKKKKK0: cKXXc cKc cXd'cxkxc'. :KXNc  :Ko'cx0Xd,,,,,dX0kc'oKc :XNXc :KKKK0K00     //
//    0000KKK0l',:,'dXc :0: cKc :KXKOd, :KXXc  :0c :Kd':dddddc'oXc :0c :KXKc ;0KKK0000     //
//    000K00l.. ... .'. .'. .'. .'''''. .','.  .'. .'. .'''''. .,. .'. .,,'. ..l0K00K0     //
//    0000K0: 'llooooooooooooooooolloooooooooooooooooooooooooooooooloooloooll' :0KK000     //
//    00K000ko:'lkOkkOOOOOOOOOkkOOOOOOOOOkkOOOOkkkkkkOOOOOOOOOOkkOOOOOOkOOkl':ok000K00     //
//    00000000kd:'...'..........''''''''.................'''....'''...'...':ok00000000     //
//    0000000000kd' .clllccccccccllcccccccccccccccccccccccccccccccccccc' 'ok0000000000     //
//    000000000000: ;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx; :0K0000000000     //
//    000000000000xl;..................................................;lx000000000000     //
//    00000000OOOOkkdlllllllllllllllllllllllllllllllllllllllllllllllllldkkOOOOO0000000     //
//    00000000000000000000000000000000000000000000000000000000000000000000000000000000     //
//    00000000000000000000KKKKKKKKKKKKKKKXXXXXXXXXXKKKKKKKKKKKKKKK00000000000000000000     //
//    000000000000000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000000000000000000000000     //
//    0000000000000000000000000000000KKKKKKKKKKKKKKKKKK0000000000000000000000000000000     //
//    00000000000000000000000000000000000000000000000000000000000000000000000000000000     //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////


contract NUDS is ERC1155Creator {
    constructor() ERC1155Creator("Tasty Noodles", "NUDS") {}
}