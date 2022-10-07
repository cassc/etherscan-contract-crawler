// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fields of Expression
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    *°*OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOo*°...  ..°°*oOOOOOOOOOOOOOOOOOOOOOOOOOOOOO*°*    //
//    *°*OOOOOOOOOOOOOOOOOOOOOOOOOOOo*°.              .°*OOOOOOOOOOOOOOOOOOOOOOOOOO*°*    //
//    *°*OOOOOOOOOooooOOoOOoOOOoOo*.                      °oOOOOooOOOOOOOOOOOOOOOOO*°*    //
//    *°*ooooooooooooooooooOO#Oo*.                          .o##OOooooooooooooooooO*°*    //
//    *°*ooooooooooooooooO##OOO°                              o###Ooooooooooooooooo*°*    //
//    *°*oooooooooooooooO###OO*                               .#####Ooooooooooooooo*°*    //
//    *°*oooooooooooooO#####OO*                                o######ooooooooooooo*°*    //
//    *°*ooooooooooooO###@##OO° ....                     °°..  o#######Oooooooooooo*°*    //
//    *°*oooooooooooO######OOO*.O#oo.                   °#@#O*°*O#######O*ooooooooo*°*    //
//    *°***********#@########O####OOOo°.             .o#@@@@@@@##########O******o*o*°*    //
//    °°**********O#########O#@###OO###OOo°          °@@@@@@@@@@@@@#######O*********°*    //
//    *°*********O##########[email protected]@##@######o.          [email protected]@@@@@@@@@@@########o**********    //
//    *°********[email protected]##################O#OOOo.°°°. .   . *@@@@@@@@@@@##########o*********    //
//    *********o####################O#Ooo*oo*°*...... [email protected]@@@@@@@@@@@#######O#O*********    //
//    ***o****o#O###################OOO°°°°*° °°..... #@@@@@@@@@@@#######O###o*oo*o***    //
//    ***o**o*oOOOO#####OOOOO#@####OOOO*°°°°°°°......°@@@@@@@@@@@@#OOOOOOOOOOooo******    //
//    ***oo*o*oOOOOOOOOO#[email protected]##@@##OO*°°°°°°°°°°°°°°O##@@@@@@##OOOOOOOOOOOOooooooo**    //
//    **ooooo*[email protected]@[email protected]@O********°°°**°°°°°°*#@@#@#ooooooooooooooooooooo**    //
//    **oo****oooooooooooooooOo#@[email protected]@o*****************ooO#####Ooooooo*oooo*oooo**oooo*    //
//    **********oooooooooooooooOOOOOOoo**************oooooooooooooo**********o*ooooooo    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract EXP is ERC721Creator {
    constructor() ERC721Creator("Fields of Expression", "EXP") {}
}