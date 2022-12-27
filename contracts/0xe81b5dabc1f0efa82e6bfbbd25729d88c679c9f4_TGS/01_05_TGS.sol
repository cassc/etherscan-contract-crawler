// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Toad Galaxy Saga
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                      //
//                                                                                                                                      //
//    A long time ago in a galaxy far, far away....                                                                                     //
//                                                                                                                                      //
//    Toad Vader lived in a grand palace on the planet Frogsto, the capital of the toad galaxy.                                         //
//    From his throne, he oversaw the governance of the entire galaxy, issuing decrees and commands to his subjects.                    //
//    His rule was absolute, and those who opposed him quickly learned the consequences of crossing him.                                //
//                                                                                                                                      //
//    Despite his fearsome reputation, Toad Vader was not always a cruel ruler.                                                         //
//    In his youth, he had been a kind and benevolent toad, beloved by his subjects for his wisdom and fairness.                        //
//    But as he grew older, he became more and more power hungry, eventually becoming consumed by his own ambition.                     //
//                                                                                                                                      //
//    As the years passed, Toad Vader's rule became increasingly tyrannical,                                                            //
//    and the once-prosperous toad galaxy began to suffer under his rule.                                                               //
//    The people grew restless and discontent, longing for the days when their leader was just and kind.                                //
//                                                                                                                                      //
//    One day, a group of brave frogs decided that they could no longer stand by and watch as their leader destroyed their home.        //
//    Led by a brave and cunning frog named Princess Frogeia, they formed a rebellion against Toad Vader and his corrupt government.    //
//                                                                                                                                      //
//    To be continued....                                                                                                               //
//                                                                                                                                      //
//                                                                                                                                      //
//    Also, I might add a burn mechanism later. :)                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TGS is ERC1155Creator {
    constructor() ERC1155Creator("Toad Galaxy Saga", "TGS") {}
}