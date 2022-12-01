// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bidders' Rewards
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccclloodddddddoollccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccclodxkO0KKXXNNNNNXXXXKK0Okxdolcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccloxO0XNNWNNXKK000OOO000KKXXNNNXX0Oxdlcccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccccldkKXNNNX0Oxdolccc:::::::::;;:loxOKXNNXKkdlccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccok0XNNXOdl:;:codxkO000KKK00Okxolc;,';oxOKNNXKOdlcccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccdOXNNXOd:'':dO0XNNNNNNNNNNNNNNNNNNXK0kdo::ldOXNNX0dlcccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccldOXNNKx:',:d0XNNNNNNNNNNNNNNNNNNNNNNNNNNNNKkd::lkKNWXOdlcccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccclkXNNKx:',oOXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKxl:cxKNNXkoccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccd0NNXk:.,o0NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXkl:ckXNN0dcccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccxXNNKo''l0NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXxc:oKNNKxlcccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccclxXNN0c',xXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN0l:cONNXxlccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccldXNN0:.;kNNNNWNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKl';kXNXxlcccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccoKNN0c.;kX0O0OOO00O0KKXNNNXNNXOkkkOKNNNX0OOOO0OOO00KNNNNNNNN0c.;ONNKdcccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccclONNXo.,xNXo;::;;;:;;:cldOXNXN0:.',;xNNWKl;:;;;;;;;:cldOXNNNNNOc,oKNNOlccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccxXNNk,.oXWKo;;;lxxxkdl:,.'dXNN0:';;:xNNW0c;::lxxxxdoc:;:cdKNNNNk::kNNKdccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccclONNXl':ONNXo;;;dNWWWNKl...:0NN0c;;;:xNWN0c;;:kNNNNNNXkc,'.l0NNNKo;oKNXklcccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccco0NN0c,oXNNXo;;;dNWNNNKl...lKNNKl;;;:xNNN0c;;:kNNNNNNNNO:..'dXNNNx;:ONN0occcccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccoKNN0c;xXNNKo;;;lkkxdo:'';oKNNNKl;;;;xNNW0c;;:kNNNNNNNNXl.',lKWNNk,'dNNKocccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccoKNN0c;xNNWKl;;;:;,''...'ckXNNNKl;;;;xNNW0c;;:kNNNNNNNNNx;;;c0WNNk,.dNNKocccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccoKNN0c;dXNNKl;;;oOOOOkxc..;o0NWKl;;;;xNNW0c;;:kNNNNNNNNXd;;;lKNNNx',kNNKocccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccco0NWKo;oKNNKo;;'oXNXXNN0c,;;kNNKl;;;:xNNN0c;;:kNNNNNNNNOc;;:kXNNXo'c0NX0occcccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccckNWNx;:ONNKo,'.lXNNNNXkc;;:ONNKl;;;:xNNN0c;;:kNNNNXX0dc;;:xXNNNKl;oKNXklcccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccdKNN0c;dXWKc...,clllll:;;cxXNNKl;;;:xNNN0c;;;:ccclol:;;:oOXNNNNk::kNNKdccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccclkNNNk::kNKl',,,,,,;:clokKNNNWKo::ccxXNW0o:;,,,,;:ccldk0XNNNNNOc;dXWXxlccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccco0NNXd;;kX000000KKKKXXNNNNNNNNKKKKKXNNNNKK0000KKKKXXNNNNXNNN0l;oKNXOocccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccdKNNKl.,xXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN0l;l0NXOdlcccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccdKNNKl''oKNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNkc;o0NXOocccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccd0NNKx;'cOXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN0d::xKNXOoccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccoOXNX0o;:d0XNWNNWNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKxc:oONXKkocccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccld0NWN0o::okXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNX0dc:lkXNKOdlccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccoxKNNX0xc:cdOKNNNNNNNNNNNNNNNNNNNNNNNNNNNKOxl:cdOXNXOxllcccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccclxKXNNKOdc:coxO0XNNNNNNNNNNNNNNNNNX0kdoc:cokKNXKOdllcccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccldOKNNNXOxocccclloddxkOOOOkkxdoc;,,:lxkKNNX0kolccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccldO0XNWNX0Okdl:;;:ccccccccccldxOKNNXX0kdlcccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccloxk0KXNNNNXXKKKKKKKXKXXNNXXK0Okxolccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccloodxkkO00KKKKKK0OOOkxxdollccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccloddddooolllcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccclkOOOOkkkdlccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccoOKKKK000klccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccoOKKKK000koccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccoOKKKK000koccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccoOKKKK000klccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccoOKKKK000klccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccclllcoOKKKK000klccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccloxxxkxx0KKKK000klccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccldkO00OOO0000KK000klccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccldkO0OOO0OOOOOO0KK00koccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccoxOOOO00OOOOOOOOO0000kxdddddddollccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccokO0OOOO00OkddkOkkkkkO00OOO00OOOkdlcccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccldk0OOOOOOkkxkddO0xdxk00K0OOO000OOOkocccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccclcccccccccccccccclxOO0OOOOkkkkkOxdOKkxdxkOOOOOOOOOkxdoccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccc::::;;;;;:;,';clllcccclloxOOOOO0OOOOOOOOxdOKKOOkkkOOOOOOOOkxdolllcccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccc::::::;;;,,,,,,''',cloc':dxxc.,xKKxlodddxOO0OOO00OOOOO00Oxd0KOkO0KK00O0OOO00OOOdlccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    :::;;;;,,,,'''''............'.;dddc',lc:,.,xNWKddO0OO00OOOOOOOO0OOOOOxd00ddxk0K0000OOO0OOOkocccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ...............................''..........cKWNxok0OO0OOOOOOOOO0OOOOOxd00kddddxkkkkkkkkkdolccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    .......................................'...;kWW0oxOOOOOOOOOOOOOOOOOOOxdO0OOOOOOkkkOOOOOOkdlccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ...........................................'oXWXxdO0OOO0OO00OOOOOOO00xdxxxOKKKK0OOOOOOOOOkoccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ............................................:0WWOox0OOOOOOOOOOOOOO0OOxdxddxOOO00OOOOOkkkxolccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    .............................................oXWKodOOOOOOOOOOOOOOOOOOxdOOkxkxkkkkkOOOkxolccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ............................................ ,OXKxokOOOOOOOOOOOOOOOO0xodkO0KK00O0OOOO0Okoccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ....................................   .  .. .dXXOoxOOOOOOOOOOOOOOO00xloxOKKK00000OOOOkdlccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ......................                 .. .  .:0NKdokOO0OOOOOOOOOOO00xodxxkOkkOOxxddoollcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ............                            . .   'xXXkoxkkOOOOOOOOOOOOOOdoO0000OO0koccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ...                                     . ..  .lKN0ololoxxkkkxxxxddooloOKKK0000koccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    .......      .........          ....    ....   ,xOkocccccllllllccccccclk0OOOOOkxlccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//                    .......  ..........   .   .....':lccccccccccccccccccccclllllllllcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//                   ....  ...       .......'',,;;::cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//                   .     .......'',,;;::cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ...        .......'',,;;::cccclccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//     .......'',,;:::cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ,,;:::cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BDR is ERC1155Creator {
    constructor() ERC1155Creator() {}
}