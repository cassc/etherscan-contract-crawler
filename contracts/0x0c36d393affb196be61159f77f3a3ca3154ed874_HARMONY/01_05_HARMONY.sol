// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Harmony
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                          ..                         :*.                                        //
//                   @@@@@@@[email protected]@#  [email protected]# @@@@@@@   %@-  [email protected]@   [email protected]@-   @@@@@@+ @@@   %@@: [email protected]@@@@- [email protected]@+  [email protected]#[email protected]@. [email protected]@:                   //
//                   @@@@@@@[email protected]@#  [email protected]# @@@@@@%   %@-  [email protected]@   @@@@   @@@@@@@[email protected]@@@ :@@@::@@@@@@@[email protected]@@: [email protected]# @@= @@%                    //
//                     [email protected]@   @@#  [email protected]# @@-       %@-  [email protected]@  [email protected]@@@-  @@+  @@[email protected]@@@[email protected]@@@:@@#   #@@[email protected]@@@[email protected]# [email protected]@[email protected]@                     //
//                     [email protected]@   @@@@@@@# @@@@@@    %@@@@@@@  #@-*@*  @@*[email protected]@[email protected]@@@@@#@@[email protected]@:   #@@[email protected]@%@#[email protected]#  #@@@=                     //
//                     [email protected]@   @@@@@@@# @@@@@@    %@@@@@@@  @@[email protected]@  @@@@@@@ @@#@@@[email protected]@[email protected]@-   #@@[email protected]@:@@@@#  [email protected]@@                      //
//                     [email protected]@   @@#  [email protected]# @@-       %@-  [email protected]@ @@@@@@@* @@#*@@  @@# @= @@:@@%   %@@[email protected]@ [email protected]@@#   #@=                      //
//                     [email protected]@   @@#  [email protected]# @@@@@@@   %@-  [email protected]@:@@@@@@@@ @@[email protected]@% @@# .  @@:[email protected]@@@@@@[email protected]@  [email protected]@#   #@=                      //
//                     [email protected]@   @@#  [email protected]# @@@@@@@   %@-  [email protected]@[email protected]@    @@[email protected]@+ :@@[email protected]@#    @@: :@@@@@: [email protected]@   @@#   #@=                      //
//                                                                                     -*:                                        //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                          @@@@*[email protected]#  @@   [email protected]@@:[email protected]@@@@#@@@% [email protected]@@@#@@  [email protected]                                          //
//                                          @@=#@%#@[email protected]  [email protected]@#@*[email protected]@%%##@@@@%[email protected]@%%[email protected]@* [email protected]                                          //
//                                          @@[email protected]* @@@%   *@:.::[email protected]#--:#@. @@[email protected]+-- @@@[email protected]                                          //
//                                          @@@@@. [email protected]@    @@ [email protected]@[email protected]@@@@#@@@@%[email protected]@@@:@%@@#@                                          //
//                                          @@  %@ :@+    *@. :@[email protected]#   #@[email protected]@[email protected]   @% %@@                                          //
//                                          @@@@@% [email protected]+    [email protected]@@@@[email protected]@@@@#@[email protected]@@@@#@% [email protected]@                                          //
//                                          -----.  -.     :=#-: ----::-  --.----:::  --                                          //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HARMONY is ERC1155Creator {
    constructor() ERC1155Creator("The Harmony", "HARMONY") {}
}