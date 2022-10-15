// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mason Eve
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//       %        .#         :-         .*@%-         -#@#-       :+       @[email protected]         [email protected]@@@@@@@. *@@:     :@@%  :@@@@@@@@        //
//      [email protected]=       #@         @@        #@@@@@@=     [email protected]@@@@@@=     [email protected]*      @[email protected]         :@@@@@@@@. [email protected]@%     *@@+  :@@@@@@@@        //
//      :@@      :@@        :@@-      :@@@@@@@*    [email protected]@@@@@@@@+    [email protected]@#     @[email protected]         :@@@@@@@@.  %@@.   [email protected]@@   :@@@@@@@@        //
//      [email protected]@+     %@@.       %@@%      *@@-  -%    [email protected]@@#:.:#@@@-   [email protected]@@#    @[email protected]         :@@*        [email protected]@#   [email protected]@*   :@@=             //
//      [email protected]@@.   [email protected]@@:      [email protected]@@@:     *@@+        #@@+     [email protected]@#   [email protected]@@@#   @[email protected]         :@@*         @@@   @@@.   :@@=             //
//      %@@@+   %@@@+      *@@@@#     [email protected]@@#-      @@%       %@@.  [email protected]@@@@%  @[email protected]         :@@*         [email protected]@* [email protected]@*    :@@+             //
//      @@@@@. [email protected]@@@%     [email protected]@##@@:     [email protected]@@@#:   :@@*       *@@:  [email protected]@*%@@%[email protected]@         :@@@@@@@.    [email protected]@@ %@@:    :@@@@@@@         //
//     [email protected]@%@@* %@@@@@     [email protected]@[email protected]@*      -%@@@@:  :@@*       *@@:  [email protected]@=.%@@@@[email protected]         :@@@@@@@.     *@@#@@#     :@@@@@@@         //
//     :@@-%@@*@@=*@@    [email protected]@%  #@@.       -%@@@   @@%       %@@.  [email protected]@= .%@@@[email protected]         :@@%****      [email protected]@@@@:     :@@%****         //
//     [email protected]@.:@@@@% [email protected]@.   [email protected]@%##%@@*        [email protected]@@   #@@+     [email protected]@#   [email protected]@=  [email protected]@@[email protected]         :@@*           #@@@#      :@@=             //
//     [email protected]@  #@@@= [email protected]@-   @@@@@@@@@@    %-  [email protected]@@   [email protected]@@#:.:#@@@-   [email protected]@=   [email protected]@[email protected]         :@@*           [email protected]@@-      :@@=             //
//     #@@  [email protected]@%  [email protected]@+  [email protected]@@%%%%@@@+  :@@@@@@@%    [email protected]@@@@@@@@+    [email protected]@=    [email protected]@         :@@@@@@@@.      %@%       :@@@@@@@@        //
//     @@@   #@-   @@#  %@@      @@%  [email protected]@@@@@@      [email protected]@@@@@@=     [email protected]@=     [email protected]@         :@@@@@@@@.      :@-       :@@@@@@@@        //
//    [email protected]@%   .#    @@@ :@@+      [email protected]@:   -#@%-         -#@#-       :@@=      .%         [email protected]@@@[email protected]       #        :@[email protected]@@        //
//                                                                                                                                //
//                                                                                                                                //
//     www.masoneve.com/                                                                                                          //
//     www.instagram.com/masoneve/                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MASON is ERC721Creator {
    constructor() ERC721Creator("Mason Eve", "MASON") {}
}