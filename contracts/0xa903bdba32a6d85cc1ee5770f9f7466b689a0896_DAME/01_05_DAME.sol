// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Fine Line
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                                           .:.                    //
//                                                                        :*@@@@@#=                 //
//                                                         .:   .=-      *@@@@@@@@@@-               //
//              :-====-:.                           :-.  :%@@@*[email protected]@@@=   [email protected]@@@=:[email protected]@@@@=              //
//          .+#@@@@@@@@@@@#=.            :-:.     .#@@@#[email protected]@@@@@@@@@@@#  #@@@*   [email protected]@@@@              //
//         [email protected]@@@%*+++*#%@@@@@#-        .#@@@@%*+: [email protected]@@@@@@@@@@@@@@@%@@%.*@@@#   :@@@@@   .=##=      //
//        [email protected]@@%-        .=#@@@@%-     .%@@@@@@@@@+:@@@@@@@@@@%@@@@@**@@%#@@@@@@%@@@@@#   %@@@@=     //
//       [email protected]@@%.            :#@@@@#.  *@@@@@@@@@@@@[email protected]@@@@@@@@@%[email protected]@@@@:%@@@@@@@@@@@@@%=   *@@@@@*     //
//       @@@@.               -%@@@@[email protected]@@@@@%@@@@@@@@#@@@@@@@@@@[email protected]@@@*:@@@@@#@@@@+-:    [email protected]@@@@@+     //
//      [email protected]@@#  .               *@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@% [email protected]@@@:[email protected]@@@-*@@@@+    [email protected]@@@@@@.     //
//      [email protected]@@# [email protected]@*.             #@@@@@@@@@#*@@@@@@@@@@@@@[email protected]@@@@= *@@@% %@@@# [email protected]@@@@*[email protected]@@@@@@=      //
//      [email protected]@@@ [email protected]@@@+           *@@@@@@-#@@@.-+#@@@@@@@@@@[email protected]@@@@. %@@@+:@@@@- .*@@@@@@@@@@@@+       //
//      [email protected]@@@= [email protected]@@@%.        #@@@@@@@%[email protected]@@=  [email protected]@@@@@@@@@# %@@@@* [email protected]@@@:[email protected]@@%   :+%@@@@@@@#-        //
//       [email protected]@@@. [email protected]@@@@=     :%@@@@@%@@@+#@@%   @@@@@@@@@@@ [email protected]@@@@. .=*+: :*#+      :=+++=.          //
//        %@@@#  :%@@@@=   [email protected]@@@@#[email protected]@@@[email protected]@@* [email protected]@@@@@@@@@@: .=*#=                                   //
//        .%@@@#  .%@@@@-.#@@@@@*   %@@@[email protected]@@+#@@@@*%@@@@@:                                         //
//         .%@@@%: .%@@@@@@@@@@-    #@@@= *@@@@@@@#  :*#*-                                          //
//           [email protected]@@@*[email protected]@@@@@@@+      #@@@=  -*@@@@+                                                  //
//            .*@@@@@@@@@@@*.      .%@@@.     ..                                                    //
//              .-*#%@@@@@@%.      [email protected]@@+                                                            //
//                     .%@@@@:    [email protected]@@#                                                             //
//                      .%@@@@=:-*@@@%.                                                             //
//                       .#@@@@@@@@@*.                                                              //
//                         %@@@@@*-.                                                                //
//                         .#@@@@*                                                                  //
//                           .=*+:                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract DAME is ERC721Creator {
    constructor() ERC721Creator("A Fine Line", "DAME") {}
}