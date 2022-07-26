// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mario Domingos
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                       .*oOOo°                                                              //
//                                                                     [email protected]@@@#@@@@                                                             //
//                                                                   [email protected]@#[email protected]@@@                                                            //
//                                                                 [email protected]@@#oOoOO#[email protected]@@@.                                                          //
//                                                               [email protected]@@###OO##OOOoO##@@o*                                                       //
//                                                             *@@@##Oo****°**oo*O#@@@@@o                                                     //
//                                                          .*@@@#*°°***oOOOOOoooo#@@@@#@@*                                                   //
//                                                        [email protected]@@@@°°oO##oO******ooO##@@@@[email protected]#o                                                 //
//                                                    ..**[email protected]@##@@*OO*°**OOoooOooOO##[email protected]@@@#OO##°                                               //
//                                         ....°.......°*[email protected]#OoO#@#O*o°  o**OoOo*oo*O#OOo.#@#O#@o°°                                            //
//                           ........... .. .*...*****oOOOo*[email protected]@##oo.#*°*.   °***[email protected]*.#@@@#Oooo*°...................                       //
//                                 .......  .  °**ooOOoo*°°*[email protected]@#@@Ooo°°. °°OO*°*@@*O°[email protected]@@@@oo*°°°°.    ......                              //
//                                ..........  .Oo   .°°°°°**[email protected]@[email protected]@#O*°..o#**  oo#@*O°@@[email protected]@@#**°. .. ..°.....                               //
//                                    ....°°°...°°°.°...°**[email protected]#[email protected]@#*°°O#o.    [email protected]@###oO#O*°.  °**°.                                    //
//                                         ...°°..*o  .°****ooO#O#@#o*o#@o.    . *[email protected]@@##o*ooo°°°*o°.                                       //
//                                             ... °o.°****ooO#O#@O°[email protected]##° ... . °***@[email protected]##O*°**O°.......                                      //
//                                              ....°*****ooO#[email protected]#°o#OO*   .  °°.°*°@##@O#oo.°°o° .*....                                      //
//                                              .... °O°***OOo*@@o.#@O#.   ...*...*°@#@#O#oo.°..°°*.    ..                                    //
//                                                ....oO**o**°[email protected]@°°@OO°   .. °*.. °*@@@O##o* ..°°.   ..                                       //
//                                                    .#**°*°°[email protected]#[email protected]#°     ° .o.. .*#@@O#O°° ...                                              //
//                                                     *#.°°.*[email protected]*[email protected]@o °    .°.*°.  [email protected]#@@#O. ..                                                //
//                                                  ....O°°°.o#[email protected]@ °      °°*°..  [email protected]#@#O...   ...                                           //
//                                                    . *o°.*@#°°@@.°..      **°°..  #[email protected]@O.    ..                                             //
//                                                      .O*°[email protected]°[email protected] .°..°°.   °o°°.  °#[email protected]°                                                   //
//                                                       **[email protected]°.*#@  .o.    .°.  ***.. [email protected]#*                                                   //
//                                                       °[email protected]*.o*@*  °o.      .o. o**. .O#@o.                                                  //
//                                                       .#* o°@#   *o         o°.o°*. *O##°                                                  //
//                                                       oo.*°O#.. .o.          * °°.*[email protected]*                                                  //
//                                                      oo.°°#O.   **  .      .. ..*..o.°ooO.                                                 //
//                                                    .o*.°°OO°.  °* ..         ° °°° °* o*o*.                                                //
//                                                   .**°°°O*..  °* .        .   °.°*..o.°o**.                                                //
//                                                  .°°°.°O*..  °*..  .        .  °.°* °*.o**.                                                //
//                                                  °°°.°o°..  °*.. .°        . .  °.°°.*°°o°.                                                //
//                                                 ....°*°.   °*.. °° .      ... .. °.*°.*°o°.                                                //
//                                                ....°°°.  .°°.. °. .        ...  . ..o°°**°                                                 //
//                                                .....°°  .°..  ° ..           ..  . ..**°o*                                                 //
//                                                    °°  °*.  .. .              .°.  . .**o*.                                                //
//                                                   .° .*°   ....                 ..  .. °oO.                                                //
//                                                  .°°°°.  ....                     .. ....oO.                                               //
//                                                 .**..  .°.                          ......°o*                                              //
//                                              .°°°.  ....                                ...°*o*.                                           //
//                                        ....°°°°......                                      ...***°°°....                                   //
//                            ............°°°°°....                                                ...°°°°°°............                      //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SNDAYS is ERC721Creator {
    constructor() ERC721Creator("Mario Domingos", "SNDAYS") {}
}