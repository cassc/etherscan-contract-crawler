// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gutter Prints Digital Wearables
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                     =+**+-                ==:*- :.                               //
//                                 --%@@@@@@@@+          :%@@@@@@@@+-                               //
//                                [email protected]@@@@@@@@@@@#        [email protected]@%%@@@@@@@@++                             //
//                            .= :@@##@@@@@@@@@@+     .#@@=*@@@@@@@@@@%.                            //
//                            :-:@@*@@@@@@@@@@@@%    .%@@-#@@@@@@@@@@@@#.                           //
//                              %@[email protected]@@@@@@@@@@@@@  [email protected]@@*[email protected]@@@@@@@@@@@@@=                           //
//                             [email protected]@[email protected]@@@@@@@@@@@@@  -%@@@-#@@@@@@@@@@@@@@%                           //
//                            :@@@##@@@@@@@@@@@@@:  [email protected]@@[email protected]@@@@@@@@@@@@@*       .                   //
//                            -*@@@[email protected]@@@@@@@@@@@@+  [email protected]@@[email protected]@@@@@@@@@@@@@.    *[email protected]@*%*                //
//                              %@@@+*@@@@@@@@@@@* *@@@%:@@@@@@@@@@@@@@-.  =%@@@@@@@#.              //
//                              [email protected]@@@@*=*@@@@@@@@= -%@@**@@@@@@@@@@@@@- ::@@%@@@@@@@@@.             //
//                      .+#%#+=. [email protected]@@@@-*@@@@@@%.  [email protected]@@#@@@@@@@@@@@*.-*:@@=#@@@@@@@@@*             //
//                    :%@@@@@@@@*  [email protected]@@@*[email protected]@@@=     [email protected]@@@@@@@@@@@*:    *@%[email protected]@@@@@@@@@%             //
//                   :@@@%@@@@@@@%. #=-=#@@@@@= -**.  [email protected]@@@@@@@#*:::    :%@+#@@@@@@@@@+             //
//                  [email protected]@@*#@@@@@@@@%  .#. .+*+::#@@@@+.#@@@%*+---======-:[email protected]@%@@@@@@@@=              //
//                  @@@@[email protected]@@@@@@@@@*  =%##**#@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.              //
//                  [email protected]@##@@@@@@@@@@@*. [email protected]@@@@@@@@@@@@# @@@*@@@@@@@@@@@@@@@@@@@@@@@*::               //
//                   %@%*@@@@@@@@@@@=  [email protected]@@@@@@@@@@@@* *@@*%%%%@@@@@@@@@@@@@@@@-                    //
//                   [email protected]@##@@@@@@@@@@% #@@@@@@@@@@@@@@@ [email protected]@@%%%[email protected]@@@@@@@@@@@@@@@@:                   //
//                    @@@[email protected]@@@@@@@@@ :@@@@@@@@@@@@@@@%  [email protected]@+%@@@@@@@@@@@@@@@@@:                  //
//                    ##@%[email protected]@@@@@@@= #@@@@@@@@@@@@@@#:.=**  *@@#@@@@@#%@@@@@@@@@@+:                 //
//                      %@**#@@@@@* [email protected]@@@@@*@@@@#+-:=%@@@@*  #@@@@@@@[email protected]@@@@@@@@@+                  //
//                      [email protected]@@@@@@%-.*@@@@@@# .:..-*%@@@@@@@@*  :@@@@@@#[email protected]@@@@@@@@*                   //
//                      :#=+**+::*@@@@@@- ..=*@@@@@@@@@@@@@@%- [email protected]@@@@@@@@@@@@@@@                    //
//                       =-  :*%@@@@*-.*.*@@@#%@@%@@@@@@@@@@@@#.#@@@@@@@@@@@@@@@                    //
//                      .=-.*@@@@@@-    .##=. =%@@%@@@@@@@@@@@@[email protected]@@@@@@@@@@@#[email protected]                    //
//                      .:[email protected]@%*%@@@#:++  .+ -*=*@@@@@@@@@@@@@@%[email protected]@@@@@@@@@@%  :                    //
//                       #@@+*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@# [email protected]@@@@@@@@#=.                        //
//                      [email protected]@*[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*@-.%@@@@@[email protected]: -                        //
//                      [email protected]@%.%@@@@@@@@@@@@@@@@@@@@@@@@@@%=  :[email protected]@@@@@#: :*                           //
//                      [email protected]@@*:#*+*+%@@@@@@@@@@@@@@@@@@%:  .:[email protected]@@@@@:                                //
//                       @%@@##@@@@=*%#%%@@@@@@@@@@@@*  . :%@@@@@@= :.                              //
//                         %@@@%##@@%%@@@%%%@@@@@@@@%   :.%@@@@@@# -.                               //
//                         :-.*-* .%@@@@@@@@@@@@@@@@%   [email protected]@@@@@@%  :.                               //
//                             :    :[email protected]*   :---:[email protected]@@%  [email protected]@@###*=                                    //
//                                    =:         :@@+ :@@%:                                         //
//                                                =*  .*+                                           //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract GPDW is ERC1155Creator {
    constructor() ERC1155Creator("Gutter Prints Digital Wearables", "GPDW") {}
}